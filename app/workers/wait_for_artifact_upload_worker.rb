# frozen_string_literal: true

class WaitForArtifactUploadWorker < BaseWorker
  MIN_CONTENT_LENGTH = 5.bytes      # to avoid processing empty or invalid artifacts
  MAX_CONTENT_LENGTH = 25.megabytes # to avoid downloading large artifacts

  sidekiq_options queue: :critical,
                  dead: false

  def perform(artifact_id, enqueued_at = Time.current.iso8601)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.waiting?

    # wait until the artifact is uploaded
    client = artifact.client

    client.wait_until(:object_exists, bucket: artifact.bucket, key: artifact.key) do |w|
      w.max_attempts = nil
      w.delay        = 30

      w.before_wait do |attempts|
        throw :failure if
          # Wait up to 1 hour for the artifact to be uploaded. We're using
          # the enqueue time so that we can accurately support job retries,
          # e.g. in case the job is stopped and restarted.
          enqueued_at.to_time < 1.hour.ago &&
          attempts > 0
      end
    end

    # get artifact metadata
    obj = client.head_object(bucket: artifact.bucket, key: artifact.key)

    artifact.update!(
      content_length: obj.content_length,
      content_type: obj.content_type,
      etag: obj.etag.delete('"'),
      status: 'PROCESSING',
    )

    NotifyArtifactUploadWorker.perform_async(
      artifact.id,
      artifact.status,
    )

    # check if it's a supported package artifact e.g. gem, npm package, etc.
    case artifact
    in filetype: ReleaseFiletype(:gem), engine: ReleaseEngine(:rubygems) if artifact.content_length.in?(MIN_CONTENT_LENGTH..MAX_CONTENT_LENGTH)
      # FIXME(ezekg) reject and warn if artifact filesize is unacceptable
      ProcessRubyGemWorker.perform_async(artifact.id)
    else
      NotifyArtifactUploadWorker.perform_async(
        artifact.id,
        'UPLOADED',
      )
    end
  rescue Aws::Waiters::Errors::WaiterFailed
    NotifyArtifactUploadWorker.perform_async(
      artifact.id,
      'FAILED',
    )
  end
end
