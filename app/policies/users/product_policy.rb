# frozen_string_literal: true

module Users
  class ProductPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('product.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record.all? { it == bearer }
        allow!
      in role: Role(:user) if user == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('product.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record == bearer
        allow!
      in role: Role(:user) if user == bearer
        allow!
      else
        deny!
      end
    end
  end
end
