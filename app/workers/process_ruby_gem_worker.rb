# frozen_string_literal: true

require 'rubygems/package'

class ProcessRubyGemWorker < BaseWorker
  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # download the gem
    client = artifact.client
    gem    = client.get_object(bucket: artifact.bucket, key: artifact.key)
                   .body

    # parse the gem
    gemspec = Gem::Package.new(gem)
                          .spec

    ReleaseManifest.create!(
      account_id: artifact.account_id,
      environment_id: artifact.environment_id,
      release_id: artifact.release_id,
      release_artifact_id: artifact.id,
      content: gemspec.to_yaml,
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
