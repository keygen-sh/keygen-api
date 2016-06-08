module Api::V1
  class PasswordsController < Api::V1::BaseController
    scope_by_subdomain

    before_action :set_user, only: [:reset]

    def reset
      @user.send_password_reset if @user
    end

    private

    def set_user
      @user = @current_account.users.find_by_email email_params
    end

    def email_params
      params.require :email
    end
  end
end
