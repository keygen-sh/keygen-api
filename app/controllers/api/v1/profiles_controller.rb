module Api::V1
  class ProfilesController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!

    # GET /profile
    def show
      authorize current_bearer

      render json: current_bearer
    end
  end
end
