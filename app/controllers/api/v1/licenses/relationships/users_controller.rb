module Api::V1::Licenses::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/user
    def show
      @user = @license.user
      authorize @user

      render jsonapi: @user
    end

    private

    def set_license
      @license = current_account.licenses.find params[:license_id]
      authorize @license, :show?
    end
  end
end
