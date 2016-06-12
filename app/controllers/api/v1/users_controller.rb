module Api::V1
  class UsersController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:index, :show, :update, :destroy]
    before_action :set_user, only: [:show, :update, :destroy]

    # GET /users
    def index
      @users = @current_account.users.all
      authorize @users

      render json: @users
    end

    # GET /users/1
    def show
      authorize @user

      render json: @user
    end

    # POST /users
    def create
      authorize @user

      @user = @current_account.users.new user_params

      if @user.save
        render json: @user, status: :created, location: v1_user_url(@user)
      else
        render json: @user, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /users/1
    def update
      authorize @user

      if @user.update(user_params)
        render json: @user
      else
        render json: @user, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /users/1
    def destroy
      authorize @user

      @user.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = @current_account.users.find_by_hashid params[:id]
      @user || render_not_found
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit :name, :email, :password
    end
  end
end
