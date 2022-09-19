# frozen_string_literal: true

module Policies
  class EntitlementPolicy < ApplicationPolicy
    authorize :policy

    def index?
      verify_permissions!('entitlement.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('entitlement.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('policy.entitlements.attach')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('policy.entitlements.detach')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
