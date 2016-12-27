module Api::V1::Users::Relationships
  class MachinesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/machines
    def index
      @machines = policy_scope apply_scopes(@user.machines).all
      authorize @machines

      render jsonapi: @machines
    end

    # GET /users/1/machines/1
    def show
      @machine = @user.machines.find params[:id]
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_user
      @user = current_account.users.find params[:user_id]
      authorize @user, :show?
    end
  end
end
