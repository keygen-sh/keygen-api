# frozen_string_literal: true

require 'minitar'
require 'zlib'

class ProcessNpmPackageWorker < BaseWorker
  MIN_TARBALL_SIZE  = 28.bytes     # to avoid processing empty or invalid gz tarballs
  MAX_TARBALL_SIZE  = 32.megabytes # to avoid downloading large tarballs
  MAX_MANIFEST_SIZE = 1.megabyte   # to avoid storing large manifests

  sidekiq_options queue: :critical,
                  retry: false

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # sanity check the package tarball
    unless artifact.content_length.in?(MIN_TARBALL_SIZE..MAX_TARBALL_SIZE)
      raise PackageNotAcceptableError, 'unacceptable filesize'
    end

    # download the package tarball in chunks to reduce memory footprint
    client = artifact.client
    enum   = Enumerator.new do |yielder|
      client.get_object(bucket: artifact.bucket, key: artifact.key) do |chunk|
        yielder << chunk
      end
    end

    # wrap the enumerator to provide an IO-like interface
    tgz = EnumeratorIO.new(enum)

    # gunzip the package tarball
    tar = gunzip(tgz)

    # keep a ref to the manifest
    manifest = nil

    # unpack the package tarball
    unpack tar do |archive|
      # NOTE(ezekg) npm prefixes everything in the archive with package/
      entry = archive.find { it.name in 'package/package.json' }

      raise PackageNotAcceptableError, 'manifest at package/package.json must exist' if
        entry.nil?

      raise PackageNotAcceptableError, 'manifest must be a package.json file' unless
        entry.file?

      raise PackageNotAcceptableError, 'manifest is too big' if
        entry.size > MAX_MANIFEST_SIZE

      # parse/validate and minify the manifest
      content = JSON.parse(entry.read)
                    .to_json

      manifest = ReleaseManifest.create!(
        account_id: artifact.account_id,
        environment_id: artifact.environment_id,
        release_id: artifact.release_id,
        release_artifact_id: artifact.id,
        content_digest: "sha512-#{Digest::SHA512.hexdigest(content)}",
        content_type: 'application/vnd.npm.install-v1+json',
        content_length: content.bytesize,
        content_path: 'package.json',
        content:,
      )
    end

    # not sure why GzipReader#open doesn't take an IO ala every other IO-like?
    tar.close

    # we can assume package tarball is invalid if there's no manifest
    raise PackageNotAcceptableError, 'manifest is missing' if
      manifest.nil?

    artifact.update!(status: 'UPLOADED')

    BroadcastEventService.call(
      event: 'artifact.upload.succeeded',
      account: artifact.account,
      resource: artifact,
    )
  rescue PackageNotAcceptableError,
         ActiveRecord::RecordInvalid,
         JSON::ParserError,
         Zlib::Error,
         Minitar::UnexpectedEOF,
         Minitar::Error,
         IOError => e
    Keygen.logger.warn { "[workers.process-npm-package-worker] Error: #{e.class.name} - #{e.message}" }

    artifact.update!(status: 'FAILED')

    BroadcastEventService.call(
      event: 'artifact.upload.failed',
      account: artifact.account,
      resource: artifact,
    )
  end

  private

  def gunzip(io)    = Zlib::GzipReader.new(io)
  def unpack(io, &)
    Minitar::Reader.open(io, &)
  rescue ArgumentError => e
    case e.message
    when /is not a valid octal string/ # octal encoding error
      raise PackageNotAcceptableError, e.message
    else
      raise e
    end
  end

  class PackageNotAcceptableError < StandardError
    def backtrace = nil # silence backtrace
  end
end
