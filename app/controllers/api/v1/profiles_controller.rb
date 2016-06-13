module Api::V1
  class ProfilesController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_user, only: [:show]

    # GET /profile
    def show
      authorize @user

      render json: @user
    end

    private

    def set_user
      @user = @current_user
    end
  end
end
