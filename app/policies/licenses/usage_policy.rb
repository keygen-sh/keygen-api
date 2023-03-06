# frozen_string_literal: true

module Licenses
  class UsagePolicy < ApplicationPolicy
    authorize :license

    def increment?
      verify_permissions!('license.usage.increment')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        !license.policy.protected?
      in role: { name: 'license' } if license == bearer
        allow!
      else
        deny!
      end
    end

    def decrement?
      verify_permissions!('license.usage.decrement')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end

    def reset?
      verify_permissions!('license.usage.reset')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
