# frozen_string_literal: true

class WaitForArtifactUploadWorker < BaseWorker
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

    # check if it's a supported package artifact e.g. gem, npm package, etc.
    case artifact
    in filetype: ReleaseFiletype(:gem), engine: ReleaseEngine(:rubygems)
      BroadcastEventService.call(
        event: 'artifact.upload.processing',
        account: artifact.account,
        resource: artifact,
      )

      ProcessRubyGemWorker.perform_async(artifact.id)
    in filetype: ReleaseFiletype(:tar), engine: ReleaseEngine(:docker)
      BroadcastEventService.call(
        event: 'artifact.upload.processing',
        account: artifact.account,
        resource: artifact,
      )

      ProcessDockerImageWorker.perform_async(artifact.id)
    in filetype: ReleaseFiletype(:tgz), engine: ReleaseEngine(:npm)
      BroadcastEventService.call(
        event: 'artifact.upload.processing',
        account: artifact.account,
        resource: artifact,
      )

      ProcessNpmPackageWorker.perform_async(artifact.id)
    else
      artifact.update!(status: 'UPLOADED')

      BroadcastEventService.call(
        event: %w[artifact.upload.succeeded artifact.uploaded], # backwards compat
        account: artifact.account,
        resource: artifact,
      )
    end
  rescue Aws::Waiters::Errors::WaiterFailed => e
    Keygen.logger.warn { "[workers.wait-for-artifact-upload-worker] Error: #{e.class.name} - #{e.message}" }

    artifact.update!(status: 'FAILED')

    BroadcastEventService.call(
      event: 'artifact.upload.failed',
      account: artifact.account,
      resource: artifact,
    )
  end
end
