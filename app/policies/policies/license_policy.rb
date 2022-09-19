# frozen_string_literal: true

module Policies
  class LicensePolicy < ApplicationPolicy
    authorize :policy

    def index?
      verify_permissions!('license.read')

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
      verify_permissions!('license.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
