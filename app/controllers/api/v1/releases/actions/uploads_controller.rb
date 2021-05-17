# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UploadsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def show
      authorize release

      signer = Aws::S3::Presigner.new
      ttl = 60.seconds.to_i
      url = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: release.s3_object_key, expires_in: ttl)
      link = release.download_links.create!(account: current_account, url: url, ttl: ttl)

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: release
      )

      render jsonapi: release, status: :see_other, location: link.url
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
      s3.delete_object(bucket: 'keygen-dist', key: release.s3_object_key)

      release.touch :yanked_at

      BroadcastEventService.call(
        event: 'release.yanked',
        account: current_account,
        resource: release
      )

      render jsonapi: release
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find params[:id]

      Keygen::Store::Request.store[:current_resource] = release
    end
  end
end
