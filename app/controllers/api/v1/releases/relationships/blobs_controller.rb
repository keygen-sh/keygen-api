# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class BlobsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def show
      authorize release, :download?

      ttl = blob_query.fetch(:ttl) { 60.seconds.to_i }
      case
      when ttl < 1.minute.to_i
        render_bad_request detail: 'must be greater than or equal to 60 (1 minute)', source: { parameter: :ttl } and return
      when ttl > 1.week.to_i
        render_bad_request detail: 'must be less than or equal to 604800 (1 week)', source: { parameter: :ttl } and return
      end

      # Assert object exists before redirecting to S3
      if !release.blob?
        s3  = Aws::S3::Client.new
        obj = s3.head_object(bucket: 'keygen-dist', key: release.s3_object_key)

        # Cache it for next time
        release.blob = obj
      end

      # TODO(ezekg) Check if IP address is from EU and use: bucket=keygen-dist-eu region=eu-west-2
      # NOTE(ezekg) Check obj.replication_status for EU
      signer = Aws::S3::Presigner.new
      url    = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl)
      link   = release.download_links.create!(account: current_account, url: url, ttl: ttl)

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: release
      )

      render jsonapi: link, status: :see_other, location: link.url
    rescue Aws::S3::Errors::NotFound,
           Timeout::Error
      Keygen.logger.warn "[releases.blob.download] No blob found: account=#{current_account.id} release=#{release.id} version=#{release.version}"

      render_not_found detail: 'does not exist or is unavailable',
        source: { pointer: '/data/relationships/blob' },
        code: :RELEASE_BLOB_UNAVAILABLE
    end

    def create
      authorize release, :upload?

      signer = Aws::S3::Presigner.new
      ttl    = 60.seconds.to_i
      url    = signer.presigned_url(:put_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl)
      link   = release.upload_links.create!(account: current_account, url: url, ttl: ttl)

      BroadcastEventService.call(
        event: 'release.uploaded',
        account: current_account,
        resource: release
      )

      render jsonapi: link, status: :temporary_redirect, location: link.url
    end

    def destroy
      authorize release, :yank?

      s3 = Aws::S3::Client.new
      s3.delete_object(bucket: 'keygen-dist', key: release.s3_object_key)

      release.touch :yanked_at
      release.blob = nil

      BroadcastEventService.call(
        event: 'release.yanked',
        account: current_account,
        resource: release
      )
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = scoped_releases.find(params[:release_id])

      Keygen::Store::Request.store[:current_resource] = release
    end

    private

    typed_query do
      on :show do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          query :ttl, type: :integer, coerce: true, optional: true
        end
      end
    end
  end
end
