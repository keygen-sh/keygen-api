# frozen_string_literal: true

module Api::V1::Releases::Actions
  class FilesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def download_file
      authorize release

      # TODO(ezekg) Generate signed S3 download for file

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: release
      )

      render jsonapi: release
    end

    def upload_file
      authorize release

      # TODO(ezekg) Generate signed S3 upload for file

      BroadcastEventService.call(
        event: 'release.uploaded',
        account: current_account,
        resource: release
      )

      render jsonapi: release
    end

    def yank_file
      authorize release

      # TODO(ezekg) Delete S3 file

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
