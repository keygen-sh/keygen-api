# frozen_string_literal: true

module Products
  class ReleasePolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :product

    def index?
      verify_permissions!('release.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow? :index, record, skip_verify_permissions: true, with: ::ReleasePolicy
      in role: { name: 'license' } if product == bearer.product
        allow? :index, record, skip_verify_permissions: true, with: ::ReleasePolicy
      else
        product.open_distribution? && record.none?(&:constraints?)
      end
    end

    def show?
      verify_permissions!('release.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePolicy
      in role: { name: 'license' } if product == bearer.product
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePolicy
      else
        product.open_distribution? && record.constraints.none?
      end
    end
  end
end
