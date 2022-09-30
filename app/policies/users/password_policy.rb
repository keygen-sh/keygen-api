# frozen_string_literal: true

module Users
  class PasswordPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[reset?]

    authorize :user

    def update?
      verify_permissions!('user.password.update')

      # TODO(ezekg) Remove this and use permissions
      deny! if
        user.has_role?(:read_only)

      user == bearer
    end

    def reset?
      verify_permissions!('user.password.reset')

      # User's without a password set cannot reset their password if account is protected
      deny! if
        user.has_role?(:user) && account.protected? && !user.password?

      # TODO(ezekg) Remove this and use permissions
      deny! if
        user.has_role?(:read_only)

      bearer.nil? || user == bearer
    end
  end
end
