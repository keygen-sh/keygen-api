module Api::V1::Users::Relationships
  class RoleController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/role
    def show
      @role = @user.role
      authorize @role

      render jsonapi: @role
    end

    private

    def set_user
      @user = current_account.users.find params[:user_id]
      authorize @user, :show?
    end
  end
end
