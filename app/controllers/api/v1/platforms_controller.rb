# frozen_string_literal: true

module Api::V1
  class PlatformsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_platform, only: [:show]

    def index
      platforms = policy_scope apply_scopes(current_account.release_platforms.with_releases)
      authorize platforms

      render jsonapi: platforms
    end

    def show
      authorize platform

      render jsonapi: platform
    end

    private

    attr_reader :platform

    def set_platform
      scoped_platforms = policy_scope(current_account.release_platforms)

      @platform = scoped_platforms.find params[:id]

      Keygen::Store::Request.store[:current_resource] = plaftorm
    end
  end
end
