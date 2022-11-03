# frozen_string_literal: true

class YankArtifactWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 25 }
  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)

    artifact.client.delete_object(
      bucket: artifact.bucket,
      key: artifact.key,
    )

    artifact.destroy
  end
end
