# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UploadsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def show
      authorize release

      # TODO(ezekg) Check if IP address is from EU and use: bucket=keygen-dist-eu region=eu-west-2
      s3 = Aws::S3::Client.new
      obj = s3.head_object(bucket: 'keygen-dist', key: release.s3_object_key)
      ttl = 60.seconds.to_i
      url = obj.presigned_url(expires_in: ttl)
      link = release.download_links.create!(account: current_account, url: url, ttl: ttl)

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: release
      )

      render jsonapi: release, status: :see_other, location: link.url
    rescue Aws::S3::Errors::NotFound
      render_unprocessable_entity detail: 'upload does not exist or is unavailable', code: :RELEASE_UPLOAD_UNAVAILABLE
    end

    def create
      authorize release

      signer = Aws::S3::Presigner.new
      ttl = 60.seconds.to_i
      url = signer.presigned_url(:put_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl)
      link = release.upload_links.create!(account: current_account, url: url, ttl: ttl)

      BroadcastEventService.call(
        event: 'release.uploaded',
        account: current_account,
        resource: release
      )

      render jsonapi: release, status: :temporary_redirect, location: link.url
    end

    def destroy
      authorize release

      s3 = Aws::S3::Client.new
      obj = s3.head_object(bucket: 'keygen-dist', key: release.s3_object_key)
      obj.delete

      release.touch :yanked_at

      BroadcastEventService.call(
        event: 'release.yanked',
        account: current_account,
        resource: release
      )

      render jsonapi: release
    rescue Aws::S3::Errors::NotFound
      render_unprocessable_entity detail: 'upload does not exist or is unavailable', code: :RELEASE_UPLOAD_UNAVAILABLE
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find params[:id]

      Keygen::Store::Request.store[:current_resource] = release
    end
  end
end
