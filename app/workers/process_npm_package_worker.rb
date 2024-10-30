# frozen_string_literal: true

require 'rubygems/package'

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

    # gunzip and untar the package tarball
    tar = gunzip(tgz)

    untar tar do |archive|
      # NOTE(ezekg) npm prefixes everything in the archive with package/
      archive.seek('package/package.json') do |entry|
        raise PackageNotAcceptableError, 'manifest must be a package.json file' unless
          entry.file?

        raise PackageNotAcceptableError, 'manifest is too big' if
          entry.size > MAX_MANIFEST_SIZE

        # the manifest is already in json format
        json = entry.read

        ReleaseManifest.create!(
          account_id: artifact.account_id,
          environment_id: artifact.environment_id,
          release_id: artifact.release_id,
          release_artifact_id: artifact.id,
          content: json,
        )
      end
    end

    artifact.update!(status: 'UPLOADED')

    BroadcastEventService.call(
      event: 'artifact.upload.succeeded',
      account: artifact.account,
      resource: artifact,
    )
  rescue PackageNotAcceptableError,
         Gem::Package::FormatError,
         Zlib::GzipFile::Error,
         Zlib::Error,
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
  def untar(io, &)  = Gem::Package::TarReader.new(io, &)

  class PackageNotAcceptableError < StandardError
    def backtrace = nil # silence backtrace
  end
end
