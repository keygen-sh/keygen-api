# frozen_string_literal: true

class WaitForArtifactUploadWorker < BaseWorker
  MANIFEST_MAX_CONTENT_LENGTH = 5.megabytes

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

    # check if it's a manifest e.g. package.json, .gemspec, etc.
    case artifact
    in filename: /.gemspec\z/, content_length: ..MANIFEST_MAX_CONTENT_LENGTH
      ProcessGemSpecManifestWorker.perform_async(artifact.id)
    else
      NotifyArtifactUploadWorker.perform_async(artifact.id)
    end
  rescue Aws::Waiters::Errors::WaiterFailed
    artifact.update!(status: 'FAILED')
  end
end
