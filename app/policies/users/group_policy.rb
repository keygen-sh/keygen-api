# frozen_string_literal: true

module Users
  class GroupPolicy < ApplicationPolicy
    authorize :user

    def show?
      verify_permissions!('group.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      in role: { name: 'user' } if user == bearer
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('user.group.update')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      else
        deny!
      end
    end
  end
end
