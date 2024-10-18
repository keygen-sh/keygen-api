# frozen_string_literal: true

require 'rubygems/package'

class ProcessGemSpecificationWorker < BaseWorker
  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # download the gemspec
    client = artifact.client
    gem    = client.get_object(bucket: artifact.bucket, key: artifact.key)
                   .body

    # parse the gemspec
    specification = Gem::Package.new(gem)
                                .spec
                                .as_json

    ReleaseSpecification.create!(
      account_id: artifact.account_id,
      environment_id: artifact.environment_id,
      release_id: artifact.release_id,
      release_artifact_id: artifact.id,
      specification:,
    )

    NotifyArtifactUploadWorker.perform_async(
      artifact.id,
      'UPLOADED',
    )
  rescue Gem::Package::FormatError
    NotifyArtifactUploadWorker.perform_async(
      artifact.id,
      'FAILED',
    )
  end
end
