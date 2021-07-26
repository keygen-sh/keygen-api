# frozen_string_literal: true

class ReleaseUploadService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidReleaseError < StandardError; end
  class YankedReleaseError < StandardError; end
  class UploadResult < OpenStruct; end

  def initialize(account:, release:)
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidReleaseError.new('release must be present') unless
      release.present?

    raise YankedReleaseError.new('has been yanked') if
      release.yanked?

    @account  = account
    @release  = release
  end

  def call
    signer   = Aws::S3::Presigner.new
    ttl      = 60.seconds.to_i
    url      = signer.presigned_url(:put_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl)
    link     = release.upload_links.create!(account: account, url: url, ttl: ttl)
    artifact = ReleaseArtifact.find_or_create_by!(
      account: account,
      product: release.product,
      release: release,
      key: release.filename,
    )

    UploadResult.new(
      redirect_url: link.url,
      artifact: artifact,
    )
  end

  private

  attr_reader :account,
              :release
end
