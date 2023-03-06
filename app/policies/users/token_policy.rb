# frozen_string_literal: true

module Users
  class TokenPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('token.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      in role: { name: 'user' } if user == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('token.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      in role: { name: 'user' } if user == bearer
        allow!
      else
        deny!
      end
    end

    def create?
      verify_permissions!('user.tokens.generate')
      verify_environment!

      deny! 'must be a user' unless
        user.user?

      case bearer
      in role: { name: 'admin' | 'developer' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      else
        deny!
      end
    end
  end
end
