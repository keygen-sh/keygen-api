module Api::V1::Users::Actions
  class PasswordController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:update_password]
    before_action :set_user, only: [:update_password, :reset_password]

    # POST /users/1/actions/update-password
    def update_password
      authorize @user

      params.require :old_password
      params.require :new_password

      if @user.try(:authenticate, params[:old_password])
        if @user.update(password: params[:new_password])
          render json: @user
        else
          render_unprocessable_resource @user
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/data/attributes/oldPassword" }
      end
    end

    # POST /users/1/actions/reset-password
    def reset_password
      skip_authorization

      params.require :password_reset_token
      params.require :new_password

      if @user.compare_encrypted_token(:password_reset_token, params[:password_reset_token])

        if @user.password_reset_sent_at < 24.hours.ago
          render_unauthorized detail: "is expired", source: {
            pointer: "/data/attributes/passwordResetToken" } and return
        end

        if @user.update(password: params[:new_password], password_reset_token: nil, password_reset_sent_at: nil)
          render json: @user
        else
          render_unprocessable_resource @user
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/data/attributes/passwordResetToken" }
      end
    end

    private

    def set_user
      @user = current_account.users.find_by_hashid params[:user_id]
    end
  end
end
