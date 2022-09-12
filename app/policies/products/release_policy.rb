# frozen_string_literal: true

module Products
  class ReleasePolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :product

    def index?
      verify_permissions!('product.releases.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow? :index, record, with: ::ReleasePolicy, inline_reasons: true
      in role: { name: 'license' } if product == bearer.product
        allow? :index, record, with: ::ReleasePolicy, inline_reasons: true
      else
        product.open_distribution? && record.none?(&:constraints?)
      end
    end

    def show?
      verify_permissions!('product.releases.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow? :show, record, with: ::ReleasePolicy, inline_reasons: true
      in role: { name: 'license' } if product == bearer.product
        allow? :show, record, with: ::ReleasePolicy, inline_reasons: true
      else
        product.open_distribution? && record.constraints.none?
      end
    end
  end
end
