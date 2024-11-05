# frozen_string_literal: true

require 'minitar'
require 'zlib'

class ProcessNpmPackageWorker < BaseWorker
  MIN_TARBALL_SIZE  = 5.bytes      # to avoid processing empty or invalid tarballs
  MAX_TARBALL_SIZE  = 25.megabytes # to avoid downloading large tarballs
  MAX_MANIFEST_SIZE = 1.megabyte   # to avoid storing large manifests

  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # sanity check the package tarball
    unless artifact.content_length.in?(MIN_TARBALL_SIZE..MAX_TARBALL_SIZE)
      raise PackageNotAcceptableError, 'unacceptable filesize'
    end

    # download the package tarball
    client = artifact.client
    tgz    = client.get_object(bucket: artifact.bucket, key: artifact.key)
                   .body

    # unpack the package tarball
    tar = gunzip(tgz)

    unpack tar do |archive|
      # NOTE(ezekg) npm prefixes everything in the archive with package/
      entry = archive.find { _1.name in 'package/package.json' }

      raise PackageNotAcceptableError, 'manifest at package/package.json must exist' if
        entry.nil?

      raise PackageNotAcceptableError, 'manifest must be a package.json file' unless
        entry.file?

      raise PackageNotAcceptableError, 'manifest is too big' if
        entry.size > MAX_MANIFEST_SIZE

      # parse/validate and minify the manifest
      json = JSON.parse(entry.read)
                 .to_json

      ReleaseManifest.create!(
        account_id: artifact.account_id,
        environment_id: artifact.environment_id,
        release_id: artifact.release_id,
        release_artifact_id: artifact.id,
        content: json,
      )
    end

    # not sure why GzipReader#open doesn't take an io?
    tar.close

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
  def unpack(io, &) = Minitar::Reader.open(io, &)

  class PackageNotAcceptableError < StandardError
    def backtrace = nil # silence backtrace
  end
end
