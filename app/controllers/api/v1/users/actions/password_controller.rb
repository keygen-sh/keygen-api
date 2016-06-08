module Api::V1::Users::Actions
  class PasswordController < BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:update_password]
    before_action :set_user, only: [:update_password, :reset_password]

    # POST /users/1/actions/update-password
    def update_password
      authorize @user

      if @user.try(:authenticate, params[:old_password])
        if @user.update(password: params[:new_password])
          render json: @user
        else
          render json: @user, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
        end
      else
        render_unauthorized "is not valid", source: {
          pointer: "/data/attributes/oldPassword" }
      end
    end

    # POST /users/1/actions/reset-password
    def reset_password
      skip_authorization

      if @user.password_reset_token == params[:password_reset_token]
        @user.reset_password_reset_token!

        if @user.password_reset_sent_at < 24.hours.ago
          render_unauthorized "is expired", source: {
            pointer: "/data/attributes/passwordResetToken" }
        elsif @user.update(password: params[:new_password])
          render json: @user
        else
          render json: @user, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
        end
      else
        render_unauthorized "is not valid", source: {
          pointer: "/data/attributes/passwordResetToken" }
      end
    end

    private

    def set_user
      @user = @current_account.users.find_by_hashid params[:user_id]
    end
  end
end
