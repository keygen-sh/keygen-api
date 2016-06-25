module Api::V1
  class ProfilesController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!

    # GET /profile
    def show
      authorize @current_user

      render json: @current_user
    end
  end
end
