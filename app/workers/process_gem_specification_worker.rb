# frozen_string_literal: true

class ProcessGemSpecificationWorker < BaseWorker
  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    gemspec       = client.get_object(bucket: artifact.bucket, key: artifact.key).body
    specification = Gem::Package.new(gemspec).spec.to_json
    release       = artifact.release

    ReleaseSpecification.create!(
      account_id: artifact.account_id,
      environment_id: artifact.environment_id,
      release_id: release.id,
      release_artifact_id: artifact.id,
      release_package_id: release.release_package_id,
      release_engine_id: release.release_engine_id,
      specification:,
    )

    NotifyArtifactUploadWorker.perform_async(
      artifact.id,
    )
  end
end
