# frozen_string_literal: true

class DownloadArtifactService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidArtifactError < StandardError; end
  class YankedReleaseError < StandardError; end
  class InvalidTTLError < StandardError; end
  class DownloadResult < OpenStruct; end

  def initialize(account:, artifact:, ttl: 1.hour, upgrade: false)
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidArtifactError.new('artifact must be present') unless
      artifact.present?

    raise YankedReleaseError.new('has been yanked') if
      artifact.yanked?

    raise InvalidTTLError.new('must be greater than or equal to 60 (1 minute)') if
      ttl.present? && ttl < 1.minute

    raise InvalidTTLError.new('must be less than or equal to 604800 (1 week)') if
      ttl.present? && ttl > 1.week

    @account  = account
    @artifact = artifact
    @release  = artifact.release
    @ttl      = ttl
    @upgrade  = upgrade
  end

  def call
    if !artifact.etag?
      # Assert artifact exists before redirecting to S3
      s3  = Aws::S3::Client.new
      obj = s3.head_object(bucket: 'keygen-dist', key: artifact.s3_object_key)

      # Cache object metadata
      artifact.update!(
        content_length: obj.content_length,
        content_type: obj.content_type,
        etag: obj.etag.delete('"'),
      )
    end

    # TODO(ezekg) Check if IP address is from EU and use: bucket=keygen-dist-eu region=eu-west-2
    # NOTE(ezekg) Check obj.replication_status for EU
    signer   = Aws::S3::Presigner.new
    url      = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: artifact.s3_object_key, expires_in: ttl&.to_i)
    link     =
      if upgrade?
        release.upgrade_links.create!(account: account, url: url, ttl: ttl)
      else
        release.download_links.create!(account: account, url: url, ttl: ttl)
      end

    DownloadResult.new(redirect_url: link.url)
  rescue Aws::S3::Errors::NotFound,
         Timeout::Error => e
    Keygen.logger.warn "[download_artifact_service] No artifact found: account=#{account.id} artifact=#{artifact.id} release=#{release.id} reason=#{e.class.name}"

    raise InvalidArtifactError.new('artifact is unavailable (ensure it has been fully uploaded)')
  end

  private

  attr_reader :account,
              :artifact,
              :release,
              :upgrade,
              :ttl

  def upgrade?
    !!upgrade
  end
end
