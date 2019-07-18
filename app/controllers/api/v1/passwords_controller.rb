# frozen_string_literal: true

module Api::V1
  class PasswordsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :set_user, only: [:reset_password]

    # POST /passwords
    def reset_password
      skip_authorization
      return unless @user

      token = @user.generate_password_reset_token

      CreateWebhookEventService.new(
        event: "user.password-reset",
        account: current_account,
        resource: @user,
        meta: {
          password_reset_token: token
        }
      ).execute

      if password_params[:meta][:deliver] != false # nil or true = send email
        @user.send_password_reset_email token: token
      end
    end

    private

    def set_user
      @user = current_account.users.find_by_email password_params[:meta][:email]
    end

    typed_parameters do
      options strict: true

      on :reset_password do
        param :meta, type: :hash do
          param :deliver, type: :boolean, optional: true
          param :email, type: :string
        end
      end
    end
  end
end
