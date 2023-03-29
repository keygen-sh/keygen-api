# frozen_string_literal: true

module Policies
  class EntitlementPolicy < ApplicationPolicy
    authorize :policy

    def index?
      verify_permissions!('entitlement.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('entitlement.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('policy.entitlements.attach')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('policy.entitlements.detach')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
