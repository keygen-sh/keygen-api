# frozen_string_literal: true

module Policies
  class PoolPolicy < ApplicationPolicy
    authorize :policy

    def index?
      verify_permissions!('key.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if policy.product == bearer
        record.all? { it.product == bearer }
      else
        deny!
      end
    end

    def show?
      verify_permissions!('key.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if policy.product == bearer
        record.product == bearer
      else
        deny!
      end
    end

    def pop?
      verify_permissions!('policy.pool.pop')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :environment)
        allow!
      in role: Role(:product) if policy.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
