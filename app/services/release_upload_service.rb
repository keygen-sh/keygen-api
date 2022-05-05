# frozen_string_literal: true

class ReleaseUploadService < BaseService
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
    signer = Aws::S3::Presigner.new
    ttl    = 1.hour # High TTL for slow upload connections: keygen => redirect => aws
    url    = signer.presigned_url(:put_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl.to_i)
    link   = release.upload_links.create!(account: account, url: url, ttl: ttl)

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
