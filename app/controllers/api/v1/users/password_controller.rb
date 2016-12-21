module Api::V1::Users
  class PasswordController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!, only: [:update_password]
    before_action :set_user, only: [:update_password, :reset_password]

    # POST /users/1/actions/update-password
    def update_password
      authorize @user

      if @user.try(:authenticate, parameters[:old_password])
        if @user.update(password: parameters[:new_password])
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

      if @user.compare_encrypted_token(:password_reset_token, parameters[:password_reset_token])

        if @user.password_reset_sent_at < 24.hours.ago
          render_unauthorized detail: "is expired", source: {
            pointer: "/data/attributes/passwordResetToken" } and return
        end

        if @user.update(password: parameters[:new_password], password_reset_token: nil, password_reset_sent_at: nil)
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

    attr_reader :parameters

    def set_user
      @user = current_account.users.find params[:id]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :update_password do
          param :old_password, type: :string
          param :new_password, type: :string
        end

        on :reset_password do
          param :password_reset_token, type: :string
          param :new_password, type: :string
        end
      end
    end
  end
end
