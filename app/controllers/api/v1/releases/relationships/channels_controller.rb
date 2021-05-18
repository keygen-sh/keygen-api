# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ChannelsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def show
      channel = release.channel
      authorize release

      render jsonapi: channel
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find params[:release_id]

      Keygen::Store::Request.store[:current_resource] = release
    end
  end
end
