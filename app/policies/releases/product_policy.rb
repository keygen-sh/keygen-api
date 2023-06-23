# frozen_string_literal: true

module Releases
  class ProductPolicy < ApplicationPolicy
    authorize :release

    def show?
      verify_permissions!('product.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        allow!
      in role: Role(:user) if bearer.products.exists?(record.id)
        allow!
      in role: Role(:license) if record == bearer.product
        allow!
      else
        deny!
      end
    end
  end
end
