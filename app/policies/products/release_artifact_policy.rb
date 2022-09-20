# frozen_string_literal: true

module Products
  class ReleaseArtifactPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :product

    def index?
      verify_permissions!('artifact.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow? :index, record, skip_permissions_check: true, with: ::ReleaseArtifactPolicy
      in role: { name: 'license' } if product == bearer.product
        allow? :index, record, skip_permissions_check: true, with: ::ReleaseArtifactPolicy
      else
        product.open_distribution? && record.none?(&:constraints?)
      end
    end

    def show?
      verify_permissions!('artifact.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow? :show, record, skip_permissions_check: true, with: ::ReleaseArtifactPolicy
      in role: { name: 'license' } if product == bearer.product
        allow? :show, record, skip_permissions_check: true, with: ::ReleaseArtifactPolicy
      else
        product.open_distribution? && record.constraints.none?
      end
    end
  end
end
