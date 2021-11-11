# frozen_string_literal: true

class ReleaseYankService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidReleaseError < StandardError; end
  class YankedReleaseError < StandardError; end

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
    s3 = Aws::S3::Client.new
    s3.delete_object(bucket: 'keygen-dist', key: release.s3_object_key)

    release.update(
      yanked_at: Time.current,
      status: 'YANKED',
    )

    artifact = release.artifact
    artifact.destroy unless
      artifact.nil?

    nil
  end

  private

  attr_reader :account,
              :release
end
