# frozen_string_literal: true

module Releases
  class ReleaseArtifactPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :release

    def index?
      verify_permissions!('artifact.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        allow!
      in role: Role(:user) if release.open? || bearer.products.exists?(release.product_id)
        allow? :index, record, skip_verify_permissions: true, with: ::ReleaseArtifactPolicy
      in role: Role(:license) if release.open? || release.product == bearer.product
        allow? :index, record, skip_verify_permissions: true, with: ::ReleaseArtifactPolicy
      else
        release.open? && release.constraints.none?
      end
    end

    def show?
      verify_permissions!('artifact.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if release.product == bearer
        allow!
      in role: Role(:user) if release.open? || bearer.products.exists?(release.product_id)
        allow? :show, record, skip_verify_permissions: true, with: ::ReleaseArtifactPolicy
      in role: Role(:license) if release.open? || release.product == bearer.product
        allow? :show, record, skip_verify_permissions: true, with: ::ReleaseArtifactPolicy
      else
        release.open? && release.constraints.none?
      end
    end
  end
end
