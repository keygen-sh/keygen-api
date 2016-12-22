module Api::V1
  class ProfilesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    # GET /profile
    def show
      authorize current_bearer

      render jsonapi: current_bearer
    end
  end
end
