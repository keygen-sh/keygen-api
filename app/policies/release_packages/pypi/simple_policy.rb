# frozen_string_literal: true

module ReleasePackages::Pypi
  class SimplePolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!

    def index?
      verify_permissions!('artifact.read')
      verify_environment!(
        strict: false,
      )

      record => [Product, *] | [] => products

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if products == [bearer]
        allow!
      in role: Role(:user)
        allow? :index, products, skip_verify_permissions: true, with: ::ProductPolicy
      in role: Role(:license)
        allow? :index, products, skip_verify_permissions: true, with: ::ProductPolicy
      else
        products.all? &:open?
      end
    end

    def show?
      verify_permissions!('artifact.read')
      verify_environment!(
        strict: false,
      )

      record => [ReleaseArtifact, *] | [] => artifacts

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if artifacts.all? { _1.product == bearer }
        allow!
      in role: Role(:user)
        allow? :index, artifacts, skip_verify_permissions: true, with: ::ReleaseArtifactPolicy
      in role: Role(:license)
        allow? :index, artifacts, skip_verify_permissions: true, with: ::ReleaseArtifactPolicy
      else
        artifacts.all? &:open?
      end
    end
  end
end
