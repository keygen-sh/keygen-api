# frozen_string_literal: true

module Releases
  class ReleasePackagePolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :release

    def show?
      verify_permissions!('package.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        allow!
      in role: Role(:user) if release.open? || bearer.products.exists?(release.product_id)
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePackagePolicy
      in role: Role(:license) if release.open? || release.product == bearer.product
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePackagePolicy
      else
        release.open? && release.constraints.none?
      end
    end

    def update?
      verify_permissions!('release.package.update')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        record&.product == bearer
      else
        deny!
      end
    end
  end
end
