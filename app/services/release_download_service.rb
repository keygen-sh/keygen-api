# frozen_string_literal: true

class ReleaseDownloadService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidReleaseError < StandardError; end
  class InvalidArtifactError < StandardError; end
  class YankedReleaseError < StandardError; end
  class InvalidTTLError < StandardError; end
  class DownloadResult < OpenStruct; end

  def initialize(account:, release:, ttl: 60, upgrade: false)
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidReleaseError.new('release must be present') unless
      release.present?

    raise InvalidArtifactError.new('artifact does not exist (ensure it has been uploaded)') unless
      release.artifact.present?

    raise YankedReleaseError.new('has been yanked') if
      release.yanked?

    raise InvalidTTLError.new('must be greater than or equal to 60 (1 minute)') if
      ttl.present? && ttl < 1.minute.to_i

    raise InvalidTTLError.new('must be less than or equal to 604800 (1 week)') if
      ttl.present? && ttl > 1.week.to_i

    @account  = account
    @release  = release
    @ttl      = ttl
    @upgrade  = upgrade
  end

  def call
    artifact = release.artifact

    # Assert artifact exists before redirecting to S3
    if !artifact.etag?
      s3  = Aws::S3::Client.new
      obj = s3.head_object(bucket: 'keygen-dist', key: release.s3_object_key)

      artifact.update!(
        content_length: obj.content_length,
        content_type: obj.content_type,
        etag: obj.etag.delete('"'),
      )
    end

    # TODO(ezekg) Check if IP address is from EU and use: bucket=keygen-dist-eu region=eu-west-2
    # NOTE(ezekg) Check obj.replication_status for EU
    signer   = Aws::S3::Presigner.new
    url      = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl)
    link     =
      if upgrade?
        release.upgrade_links.create!(account: account, url: url, ttl: ttl)
      else
        release.download_links.create!(account: account, url: url, ttl: ttl)
      end

    DownloadResult.new(
      redirect_url: link.url,
      artifact: artifact,
    )
  rescue Aws::S3::Errors::NotFound,
         Timeout::Error => e
    Keygen.logger.warn "[release_download_service] No artifact found: account=#{account.id} release=#{release.id} version=#{release.version} reason=#{e.class.name}"

    raise InvalidArtifactError.new('artifact does not exist or is unavailable (ensure it has been uploaded)')
  end

  private

  attr_reader :account,
              :release,
              :artifact,
              :upgrade,
              :ttl

  def upgrade?
    upgrade
  end
end
