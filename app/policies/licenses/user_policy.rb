# frozen_string_literal: true

module Licenses
  class UserPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('user.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allow!
      in role: { name: 'license' } if license == bearer
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('license.user.update')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
