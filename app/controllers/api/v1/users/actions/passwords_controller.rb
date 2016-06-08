module Api::V1::Users::Actions
  class PasswordsController < BaseController
    scope_by_subdomain

    before_action :set_user, only: [:update, :reset]

    # accessible_by_admin :update, :reset

    # POST /accounts/1/actions/update-password
    def update
      password = BCrypt::Password.new @user.password_digest

      if password == params[:old_password]
        if @user.update(password: params[:new_password])
          render json: @user
        else
          render json: @user, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
        end
      else
        render status: :unauthorized
      end
    end

    # POST /accounts/1/actions/reset-password
    def reset
      if @user.password_reset_token == params[:password_reset_token]
        @user.regenerate_password_reset_token!

        if @user.password_reset_sent_at < 1.minute.ago
          # TODO: Make a custom errors serializer
          render json: { errors: [{
            source: { pointer: "/data/attributes/passwordResetToken" },
            detail: "is expired"
          }]}, status: :unprocessable_entity, adapter: :json_api
        elsif @user.update(password: params[:new_password])
          render json: @user
        else
          render json: @user, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
        end
      else
        render status: :unauthorized
      end
    end

    private

    def set_user
      @user = @current_account.users.find_by_hashid params[:user_id]
    end
  end
end
