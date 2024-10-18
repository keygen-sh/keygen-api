# frozen_string_literal: true

class NotifyArtifactUploadWorker < BaseWorker
  sidekiq_options queue: :webhooks

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    artifact.update!(status: 'UPLOADED')

    BroadcastEventService.call(
      event: 'artifact.uploaded',
      account: artifact.account,
      resource: artifact,
    )
  end
end
