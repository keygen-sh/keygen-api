# frozen_string_literal: true

require 'rubygems/package'

class ProcessDockerImageWorker < BaseWorker
  MIN_TARBALL_SIZE  = 5.bytes    # to avoid processing empty or invalid tarballs
  MAX_TARBALL_SIZE  = 1.gigabyte # to avoid downloading excessive tarballs
  MAX_MANIFEST_SIZE = 1.megabyte # to avoid storing large manifests

  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # sanity check the image tarball
    unless artifact.content_length.in?(MIN_TARBALL_SIZE..MAX_TARBALL_SIZE)
      raise ImageNotAcceptableError, 'unacceptable filesize'
    end

    # download the image tarball
    client = artifact.client
    tgz    = client.get_object(bucket: artifact.bucket, key: artifact.key)
                   .body

    # gunzip and untar the image tarball
    tar = gunzip(tgz)

    untar tar do |archive|
      archive.each do |entry|
        case entry.full_name
        in 'manifest.json'
          raise ImageNotAcceptableError, 'manifest must be a manifest.json file' unless
            entry.file?

          raise ImageNotAcceptableError, 'manifest is too big' if
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
        in %r{^blobs/sha256/} if entry.file?
          key = artifact.key_for(entry.full_name)

          # skip if already uploaded
          next if
            client.head_object(bucket: artifact.bucket, key:) rescue false

          # upload blob in chunks
          client.put_object(bucket: artifact.bucket, key:) do |writer|
            while (chunk = entry.read(16 * 1024)) # write in chunks
              writer.write(chunk)
            end
          end
        else
        end
      end
    end

    artifact.update!(status: 'UPLOADED')

    BroadcastEventService.call(
      event: 'artifact.upload.succeeded',
      account: artifact.account,
      resource: artifact,
    )
  rescue ImageNotAcceptableError,
         Gem::Package::FormatError,
         Zlib::GzipFile::Error,
         Zlib::Error,
         IOError => e
    Keygen.logger.warn { "[workers.process-docker-image-worker] Error: #{e.class.name} - #{e.message}" }

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

  class ImageNotAcceptableError < StandardError
    def backtrace = nil # silence backtrace
  end
end
