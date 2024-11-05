# frozen_string_literal: true

require 'rubygems/package'

class ProcessRubyGemWorker < BaseWorker
  MIN_GEM_SIZE     = 5.bytes      # to avoid processing empty or invalid gems
  MAX_GEM_SIZE     = 25.megabytes # to avoid downloading large gems
  MAX_GEMSPEC_SIZE = 1.megabyte   # to avoid storing large gemspecs

  sidekiq_options queue: :critical

  def perform(artifact_id)
    artifact = ReleaseArtifact.find(artifact_id)
    return unless
      artifact.processing?

    # sanity check the gem
    unless artifact.content_length.in?(MIN_GEM_SIZE..MAX_GEM_SIZE)
      raise GemNotAcceptableError, 'unacceptable filesize'
    end

    # download the gem
    client = artifact.client
    gem    = client.get_object(bucket: artifact.bucket, key: artifact.key)
                   .body

    # parse the gem
    gemspec = Gem::Package.new(gem)
                          .spec

    # serialize the gemspec to yaml
    yaml = gemspec.to_yaml

    raise GemNotAcceptableError, 'gemspec is too big' if
      yaml.bytesize > MAX_GEMSPEC_SIZE

    ReleaseManifest.create!(
      account_id: artifact.account_id,
      environment_id: artifact.environment_id,
      release_id: artifact.release_id,
      release_artifact_id: artifact.id,
      content: yaml,
    )

    artifact.update!(status: 'UPLOADED')

    BroadcastEventService.call(
      event: 'artifact.upload.succeeded',
      account: artifact.account,
      resource: artifact,
    )
  rescue GemNotAcceptableError,
         ActiveRecord::RecordInvalid,
         Gem::Package::FormatError => e
    Keygen.logger.warn { "[workers.process-ruby-gem-worker] Error: #{e.class.name} - #{e.message}" }

    artifact.update!(status: 'FAILED')

    BroadcastEventService.call(
      event: 'artifact.upload.failed',
      account: artifact.account,
      resource: artifact,
    )
  end

  private

  class GemNotAcceptableError < StandardError
    def backtrace = nil # silence backtrace
  end
end
