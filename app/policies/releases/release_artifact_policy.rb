# frozen_string_literal: true

module Releases
  class ReleaseArtifactPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :release

    def index?
      verify_permissions!('release.artifacts.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(release.product.id)
        allow? :index, record, with: ::ReleaseArtifactPolicy
      in role: { name: 'license' } if release.product == bearer.product
        allow? :index, record, with: ::ReleaseArtifactPolicy
      else
        release.open_distribution? && release.none?(&:constraints?)
      end
    end

    def show?
      verify_permissions!('release.artifacts.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(release.product.id)
        allow? :show, record, with: ::ReleaseArtifactPolicy
      in role: { name: 'license' } if release.product == bearer.product
        allow? :show, record, with: ::ReleaseArtifactPolicy
      else
        release.open_distribution? && release.constraints.none?
      end
    end
  end
end
