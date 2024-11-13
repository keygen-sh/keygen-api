# frozen_string_literal: true

require 'minitar'
require 'zlib'

require Rails.root / 'lib/oci_image_layout'

class ProcessOciImageWorker < BaseWorker
  MIN_TARBALL_SIZE  = 512.bytes     # to avoid processing empty or invalid tarballs
  MAX_TARBALL_SIZE  = 512.megabytes # to avoid downloading excessive tarballs
  MAX_MANIFEST_SIZE = 1.megabyte    # to avoid storing large manifests
  MAX_BLOB_SIZE     = 512.megabytes # to avoid storing large layers

  sidekiq_options queue: :critical,
                  retry: false

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

    # unpack the image tarball
    unpack tar do |archive|
      layout = OciImageLayout.parse(archive)

      layout.each do |item|
        next unless
          item.exists?

        case item
        in OciImageLayout::Index => index
          raise ImageNotAcceptableError, 'manifest is too big' if
            index.size > MAX_MANIFEST_SIZE

          ReleaseManifest.create!(
            account_id: artifact.account_id,
            environment_id: artifact.environment_id,
            release_id: artifact.release_id,
            release_artifact_id: artifact.id,
            content_type: index.media_type,
            content_digest: index.digest,
            content_length: index.size,
            content: index.read,
          )
        in OciImageLayout::Blob => blob
          raise ImageNotAcceptableError, 'blob is too big' if
            blob.size > MAX_BLOB_SIZE

          descriptor = ReleaseDescriptor.create!(
            account_id: artifact.account_id,
            environment_id: artifact.environment_id,
            release_id: artifact.release_id,
            release_artifact_id: artifact.id,
            content_type: blob.media_type,
            content_digest: blob.digest,
            content_length: blob.size,
            content_path: blob.path,
          )

          # don't reupload if blob already exists
          next if
            client.head_object(bucket: descriptor.bucket, key: descriptor.key).successful? rescue false

          # upload blob in chunks to reduce memory footprint
          client.put_object(bucket: descriptor.bucket, key: descriptor.key, content_type: descriptor.content_type, content_length: descriptor.content_length) do |writer|
            while chunk = blob.read(16 * 1024)
              writer.write(chunk)
            end
          end
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
         OciImageLayout::Error,
         ActiveRecord::RecordInvalid,
         JSON::ParserError,
         Minitar::UnexpectedEOF,
         Minitar::Error,
         IOError => e
    Keygen.logger.warn { "[workers.process-oci-image-worker] Error: #{e.class.name} - #{e.message}" }

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
