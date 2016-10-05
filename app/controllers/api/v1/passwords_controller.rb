module Api::V1
  class PasswordsController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :set_user, only: [:reset_password]

    def reset_password
      skip_authorization

      @user.send_password_reset_email if @user
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
