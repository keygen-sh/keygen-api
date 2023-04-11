# frozen_string_literal: true

module Releases
  class ReleaseEntitlementConstraintPolicy < ApplicationPolicy
    authorize :release

    def index?
      verify_permissions!('constraint.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
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
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
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
      verify_environment!(
        # NOTE(ezekg) This seems weird, but we want to allow attaching global entitlements
        #             to shared releases, but not vice-versa. Essentially, we're checking
        #             for read permissions before inserting rows in the join table.
        strict: release.environment.nil?,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'environment' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('release.constraints.detach')
      verify_environment!(
        # NOTE(ezekg) ^^^ ditto above except for detaching.
        strict: release.environment.nil?,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'environment' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
