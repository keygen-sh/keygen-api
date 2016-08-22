module Api::V1
  class UsersController < Api::V1::BaseController
    has_scope :roles, type: :array, default: [:user]
    has_scope :product
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:index, :show, :update, :destroy]
    before_action :authenticate_with_token?, only: [:create]
    before_action :set_user, only: [:show, :update, :destroy]

    # GET /users
    def index
      @users = apply_scopes(@current_account.users).all
      authorize @users

      render json: @users
    end

    # GET /users/1
    def show
      render_not_found and return unless @user

      authorize @user

      render json: @user
    end

    # POST /users
    def create
      @user = @current_account.users.new user_params
      authorize @user

      if @user.save
        render json: @user, status: :created, location: v1_user_url(@user)
      else
        render_unprocessable_resource @user
      end
    end

    # PATCH/PUT /users/1
    def update
      render_not_found and return unless @user

      authorize @user

      if @user.update(user_params)
        render json: @user
      else
        render_unprocessable_resource @user
      end
    end

    # DELETE /users/1
    def destroy
      render_not_found and return unless @user

      authorize @user

      @user.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = @current_account.users.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit [
        :name,
        :email,
        (:password if action_name == "create"),
        (:role if @current_user&.admin?)
      ].compact, {
        # TODO: Possibly unsafe. See: http://stackoverflow.com/questions/17810838/strong-parameters-permit-all-attributes-for-nested-attributes
        meta: params.to_unsafe_h.fetch(:user, {}).fetch(:meta, {}).keys.map(&:to_sym)
      }
    end
  end
end
