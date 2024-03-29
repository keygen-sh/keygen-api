# frozen_string_literal: true

class V1x0::ReleaseUploadService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidReleaseError < StandardError; end
  class InvalidArtifactError < StandardError; end
  class YankedReleaseError < StandardError; end
  class UploadResult < OpenStruct; end

  def initialize(account:, release:)
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidReleaseError.new('release must be present') unless
      release.present?

    raise InvalidArtifactError.new('artifact must be present') unless
      release.artifact.present?

    raise YankedReleaseError.new('has been yanked') if
      release.yanked?

    @account  = account
    @release  = release
    @artifact = release.artifact
  end

  def call
    signer = artifact.presigner
    ttl    = 1.hour # High TTL for slow upload connections: keygen => redirect => aws
    url    = signer.presigned_url(:put_object, bucket: artifact.bucket, key: artifact.key, expires_in: ttl.to_i)
    link   = release.upload_links.create!(account: account, url: url, ttl: ttl)

    # Wait for the artifact to be uploaded
    WaitForArtifactUploadWorker.perform_async(artifact.id)

    # NOTE(ezekg) For v1.0 backwards compatibility
    release.update!(status: 'PUBLISHED')

    UploadResult.new(
      redirect_url: link.url,
      artifact:,
    )
  end

  private

  attr_reader :account,
              :release,
              :artifact
end
