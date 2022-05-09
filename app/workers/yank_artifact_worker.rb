# frozen_string_literal: true

class YankArtifactWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 25 }
  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)

    Aws::S3::Client.new.delete_object(
      bucket: 'keygen-dist',
      key: artifact.s3_object_key,
    )

    artifact.destroy
  end
end
