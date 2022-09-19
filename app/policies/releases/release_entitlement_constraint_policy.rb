# frozen_string_literal: true

module Releases
  class ReleaseEntitlementConstraintPolicy < ApplicationPolicy
    authorize :release

    def index?
      verify_permissions!('constraint.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(release.product.id)
        allow!
      in role: { name: 'license' } if release.product == bearer.product
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('constraint.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(release.product.id)
        allow!
      in role: { name: 'license' } if release.product == bearer.product
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('release.constraints.attach')

      case bearer
      in role: { name: 'admin' | 'developer' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('release.constraints.detach')

      case bearer
      in role: { name: 'admin' | 'developer' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
