# frozen_string_literal: true

class NotifyArtifactUploadWorker < BaseWorker
  sidekiq_options queue: :webhooks

  def perform(artifact_id, status)
    artifact = ReleaseArtifact.find(artifact_id)
    artifact.update!(status:)

    event = case status
            when 'PROCESSING'
              'artifact.upload.processing'
            when 'UPLOADED'
              %w[artifact.upload.succeeded artifact.uploaded] # backwards compat
            when 'FAILED'
              'artifact.upload.failed'
            end

    BroadcastEventService.call(
      account: artifact.account,
      resource: artifact,
      event:,
    )
  end
end
