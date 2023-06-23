# frozen_string_literal: true

module Policies
  class ProductPolicy < ApplicationPolicy
    authorize :policy

    def show?
      verify_permissions!('product.read')
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
  end
end
