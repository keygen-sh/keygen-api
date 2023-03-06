# frozen_string_literal: true

module Licenses
  class PolicyPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('policy.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
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
      verify_permissions!('license.policy.update')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        record&.product == bearer
      in role: { name: 'user' } if license.user == bearer
        !license.protected? && !record&.protected?
      else
        deny!
      end
    end
  end
end
