# frozen_string_literal: true

class V1x0::ReleaseDownloadService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidReleaseError < StandardError; end
  class InvalidArtifactError < StandardError; end
  class TooManyArtifactsError < StandardError; end
  class YankedReleaseError < StandardError; end
  class InvalidTTLError < StandardError; end
  class DownloadResult < OpenStruct; end

  def initialize(account:, release:, platform: nil, filetype: nil, ttl: 1.hour, upgrade: false)
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidReleaseError.new('release must be present') unless
      release.present?

    raise YankedReleaseError.new('has been yanked') if
      release.yanked?

    raise InvalidTTLError.new('must be greater than or equal to 60 (1 minute)') if
      ttl.present? && ttl < 1.minute

    raise InvalidTTLError.new('must be less than or equal to 604800 (1 week)') if
      ttl.present? && ttl > 1.week

    @account  = account
    @release  = release
    @platform = platform
    @filetype = filetype
    @ttl      = ttl
    @upgrade  = upgrade
  end

  def call
    artifacts = release.artifacts
    artifacts = artifacts.for_platform(platform) if platform.present?
    artifacts = artifacts.for_filetype(filetype) if filetype.present?
    artifact  = artifacts.sole

    # Assert artifact exists before redirecting to S3
    if !artifact.etag?
      client = artifact.client
      obj    = client.head_object(bucket: artifact.bucket, key: artifact.key)

      artifact.update_async(
        content_length: obj.content_length,
        content_type: obj.content_type,
        etag: obj.etag.delete('"'),
      )
    end

    redirect_url = if upgrade?
                     artifact.upgrade(ttl:)
                   else
                     artifact.download(ttl:)
                   end

    DownloadResult.new(
      redirect_url:,
      artifact:,
    )
  rescue ActiveRecord::SoleRecordExceeded
    raise TooManyArtifactsError.new('multiple artifacts are not supported by this release (see upgrading from v1.0 to v1.1)')
  rescue ActiveRecord::RecordNotFound
    raise InvalidArtifactError.new('artifact does not exist (ensure it has been uploaded)')
  rescue Aws::S3::Errors::NotFound,
         Timeout::Error => e
    Keygen.logger.warn "[release_download_service] No artifact found: account=#{account.id} release=#{release.id} version=#{release.version} reason=#{e.class.name}"

    raise InvalidArtifactError.new('artifact is unavailable (ensure it has been fully uploaded)')
  end

  private

  attr_reader :account,
              :release,
              :platform,
              :filetype,
              :upgrade,
              :ttl

  def upgrade?
    upgrade
  end
end
