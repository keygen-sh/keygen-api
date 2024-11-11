# frozen_string_literal: true

require 'minitar'
require 'zlib'

class ProcessDockerImageWorker < BaseWorker
  MIN_TARBALL_SIZE  = 512.bytes     # to avoid processing empty or invalid tarballs
  MAX_TARBALL_SIZE  = 512.megabytes # to avoid downloading excessive tarballs
  MAX_MANIFEST_SIZE = 1.megabyte    # to avoid storing large manifests

  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # sanity check the image tarball
    unless artifact.content_length.in?(MIN_TARBALL_SIZE..MAX_TARBALL_SIZE)
      raise ImageNotAcceptableError, 'unacceptable filesize'
    end

    # download the image tarball in chunks to reduce memory footprint
    client = artifact.client
    enum   = Enumerator.new do |yielder|
      client.get_object(bucket: artifact.bucket, key: artifact.key) do |chunk|
        yielder << chunk
      end
    end

    # wrap the enumerator to provide an IO-like interface
    tar = EnumeratorIO.new(enum)

    # keep a ref to the manifest
    manifest = nil

    # unpack the package tarball
    unpack tar do |archive|
      archive.each do |entry|
        case entry.name
        in 'index.json'
          raise ImageNotAcceptableError, 'manifest must be a index.json file' unless
            entry.file?

          raise ImageNotAcceptableError, 'manifest is too big' if
            entry.size > MAX_MANIFEST_SIZE

          # parse/validate and minify the manifest
          content = JSON.parse(entry.read)
                        .to_json

          manifest = ReleaseManifest.create!(
            account_id: artifact.account_id,
            environment_id: artifact.environment_id,
            release_id: artifact.release_id,
            release_artifact_id: artifact.id,
            content:,
          )
        in %r{^blobs/sha256/} if entry.file?
          key = artifact.key_for(entry.name)

          # skip if already uploaded
          next if
            client.head_object(bucket: artifact.bucket, key:).successful? rescue false

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

    # we can assume image tarball is invalid if there's no manifest
    raise ImageNotAcceptableError, 'manifest is missing' if
      manifest.nil?

    artifact.update!(status: 'UPLOADED')

    BroadcastEventService.call(
      event: 'artifact.upload.succeeded',
      account: artifact.account,
      resource: artifact,
    )
  rescue ImageNotAcceptableError,
         ActiveRecord::RecordInvalid,
         JSON::ParserError,
         Minitar::UnexpectedEOF,
         Minitar::Error,
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

  def unpack(io, &)
    Minitar::Reader.open(io, &)
  rescue ArgumentError => e
    raise ImageNotAcceptableError, e.message
  end

  class ImageNotAcceptableError < StandardError
    def backtrace = nil # silence backtrace
  end
end
