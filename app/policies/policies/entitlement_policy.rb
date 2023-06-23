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
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if policy.product == bearer
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
      in role: Role(:product) if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('policy.entitlements.attach')
      verify_environment!(
        # NOTE(ezekg) This seems weird, but we want to allow attaching global entitlements
        #             to shared policies, but not vice-versa. Essentially, we're checking
        #             for read permissions before inserting rows in the join table.
        strict: policy.environment.nil?,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :environment)
        allow!
      in role: Role(:product) if policy.product == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('policy.entitlements.detach')
      verify_environment!(
        # NOTE(ezekg) ^^^ ditto above except for detaching.
        strict: policy.environment.nil?,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :environment)
        allow!
      in role: Role(:product) if policy.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
