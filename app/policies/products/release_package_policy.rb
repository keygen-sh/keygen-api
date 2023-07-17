# frozen_string_literal: true

module Products
  class ReleasePackagePolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :product

    def index?
      verify_permissions!('package.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if product == bearer
        allow!
      in role: Role(:user) if product.open? || bearer.products.exists?(product.id)
        allow? :index, record, skip_verify_permissions: true, with: ::ReleasePackagePolicy
      in role: Role(:license) if product.open? || product == bearer.product
        allow? :index, record, skip_verify_permissions: true, with: ::ReleasePackagePolicy
      else
        product.open?
      end
    end

    def show?
      verify_permissions!('package.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if product == bearer
        allow!
      in role: Role(:user) if product.open? || bearer.products.exists?(product.id)
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePackagePolicy
      in role: Role(:license) if product.open? || product == bearer.product
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePackagePolicy
      else
        product.open?
      end
    end
  end
end
