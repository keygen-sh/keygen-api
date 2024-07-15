# frozen_string_literal: true

module Api::V1
  class ReleasePlatformsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate
    before_action :set_platform, only: %i[show]

    def index
      platforms = apply_pagination(authorized_scope(apply_scopes(current_account.release_platforms.with_releases)))
      authorize! platforms

      render jsonapi: platforms
    end

    def show
      authorize! platform

      render jsonapi: platform
    end

    private

    attr_reader :platform

    def set_platform
      scoped_platforms = authorized_scope(current_account.release_platforms)

      @platform = scoped_platforms.find(params[:id])

      Current.resource = platform
    end
  end
end
