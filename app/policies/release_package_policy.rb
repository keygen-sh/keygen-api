# frozen_string_literal: true

class ReleasePackagePolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!

  def index?
    verify_permissions!('package.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.all? { _1.product == bearer }
      allow!
    in role: Role(:user)
      allow? :index, record.collect(&:product),
        with: ::ProductPolicy,
        skip_verify_permissions: true
    in role: Role(:license)
      allow? :index, record.collect(&:product),
        with: ::ProductPolicy,
        skip_verify_permissions: true
    else
      record.all? { _1.product.open? }
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
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user)
      allow? :index, record.artifacts, context: { product: record.product },
        with: ::Products::ReleaseArtifactPolicy,
        skip_verify_permissions: true
    in role: Role(:license)
      allow? :index, record.artifacts, context: { product: record.product },
        with: ::Products::ReleaseArtifactPolicy,
        skip_verify_permissions: true
    else
      record.product.open?
    end
  end
end
