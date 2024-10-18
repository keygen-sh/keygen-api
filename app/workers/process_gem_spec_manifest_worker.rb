# frozen_string_literal: true

class ProcessGemSpecManifestWorker < BaseWorker
  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    manifest = client.get_object(bucket: artifact.bucket, key: artifact.key).body
    metadata = gemspec_to_json(manifest)
    release  = artifact.release

    ReleaseManifest.create!(
      account_id: artifact.account_id,
      environment_id: artifact.environment_id,
      release_id: release.id,
      release_artifact_id: artifact.id,
      release_package_id: release.release_package_id,
      release_engine_id: release.release_engine_id,
      metadata:,
    )

    NotifyArtifactUploadWorker.perform_async(
      artifact.id,
    )
  end

  private

  def gemspec_to_json(content) = Gem::Package.new(manifest).spec.to_json
end
