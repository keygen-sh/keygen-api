# frozen_string_literal: true

module Api::V1::Users::Actions
  class PasswordController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!, only: [:update_password]
    before_action :set_user, only: [:update_password, :reset_password]

    # POST /users/1/update-password
    def update_password
      authorize user

      if user.password? && user.authenticate(password_meta[:old_password])
        if user.update(password: password_meta[:new_password], password_reset_token: nil, password_reset_sent_at: nil)
          user.revoke_tokens(except: current_token)

          render jsonapi: user
        else
          render_unprocessable_resource user
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/meta/oldPassword" }
      end
    end

    # POST /users/1/reset-password
    def reset_password
      skip_authorization

      if user.compare_hashed_token(:password_reset_token, password_meta[:password_reset_token])
        return render_unauthorized(detail: "is expired", source: { pointer: "/meta/passwordResetToken" }) if
          user.password_reset_sent_at < 24.hours.ago

        if user.update(password: password_meta[:new_password], password_reset_token: nil, password_reset_sent_at: nil)
          user.revoke_tokens

          render jsonapi: user
        else
          render_unprocessable_resource user
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/meta/passwordResetToken" }
      end
    end

    private

    attr_reader :user

    def set_user
      @user = FindByAliasService.call(scope: current_account.users, identifier: params[:id], aliases: :email)

      Current.resource = user
    end

    typed_parameters do
      options strict: true

      on :update_password do
        param :meta, type: :hash do
          param :old_password, type: :string
          param :new_password, type: :string
        end
      end

      on :reset_password do
        param :meta, type: :hash do
          param :password_reset_token, type: :string
          param :new_password, type: :string
        end
      end
    end
  end
end
