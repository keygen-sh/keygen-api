# frozen_string_literal: true

module Users
  class PasswordPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[reset?]

    authorize :user

    def update?
      verify_permissions!('user.password.update')
      verify_environment!

      user == bearer
    end

    def reset?
      verify_permissions!('user.password.reset')
      verify_environment!

      # users without a password set cannot reset their password
      deny! if
        user.managed?

      bearer.nil? || user == bearer
    end
  end
end
