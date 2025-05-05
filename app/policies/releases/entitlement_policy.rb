# frozen_string_literal: true

module Releases
  class EntitlementPolicy < ApplicationPolicy
    authorize :release

    scope_for :active_record_relation do |relation|
      relation = relation.for_environment(environment) if
        relation.respond_to?(:for_environment)

      # NOTE(ezekg) We don't want to scope this resource to the current bearer, since
      #             e.g. a release's constraints may not 100% intersect with a license's
      #             entitlements. We still want the unknown entitlements to be shown,
      #             granted the license has permission to read the entitlements.
      relation.all
    end

    def index?
      verify_permissions!('entitlement.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        allow!
      in role: Role(:user) if bearer.products.exists?(release.product_id)
        allow!
      in role: Role(:license) if release.product == bearer.product
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
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        allow!
      in role: Role(:user) if bearer.products.exists?(release.product_id)
        allow!
      in role: Role(:license) if release.product == bearer.product
        allow!
      else
        deny!
      end
    end
  end
end
