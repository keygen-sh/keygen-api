# frozen_string_literal: true

module Licenses
  class PolicyPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('policy.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      in role: { name: 'license' } if license == bearer
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      else
        deny!
      end
    end

    def update?
      verify_permissions!('license.policy.update')

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
