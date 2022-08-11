# frozen_string_literal: true

module Api::V1
  class PasswordsController < Api::V1::BaseController
    skip_verify_authorized

    before_action :scope_to_current_account!
    before_action :set_user, only: [:reset_password]

    def reset_password
      return unless
        user.present?

      token = user.generate_password_reset_token

      BroadcastEventService.call(
        event: 'user.password-reset',
        account: current_account,
        resource: user,
        meta: {
          password_reset_token: token
        }
      )

      if password_meta[:deliver] != false # nil or true = send email
        user.send_password_reset_email(token: token)
      end
    end

    private

    attr_reader :user

    def set_user
      email = password_meta[:email].downcase

      @user = current_account.users.find_by(email: email)
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
