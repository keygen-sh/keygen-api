# frozen_string_literal: true

module Users
  class ProductPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('user.products.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      in role: { name: 'user' } if user == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('user.products.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if user.user?
        allow!
      in role: { name: 'user' } if user == bearer
        allow!
      else
        deny!
      end
    end
  end
end
