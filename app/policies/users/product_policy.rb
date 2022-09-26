# frozen_string_literal: true

module Users
  class ProductPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product'} if record.all? { _1 == bearer }
        allow!
      in role: { name: 'user' } if user == bearer
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      else
        deny!
      end
    end

    def show?
      verify_permissions!('product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if record == bearer
        allow!
      in role: { name: 'user' } if user == bearer
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      else
        deny!
      end
    end
  end
end
