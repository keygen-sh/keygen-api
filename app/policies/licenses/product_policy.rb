# frozen_string_literal: true

module Licenses
  class ProductPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('product.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      in role: Role(:user) if license.owner == bearer || bearer.licenses.exists?(license.id)
        allow!
      in role: Role(:license) if license == bearer
        allow!
      else
        deny!
      end
    end
  end
end
