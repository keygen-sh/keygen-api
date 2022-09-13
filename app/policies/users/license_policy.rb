# frozen_string_literal: true

module Users
  class LicensePolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('user.licenses.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if user.user?
        record.all? { _1.product == bearer }
      in role: { name: 'user' } if user == bearer
        record.all? { _1.user == bearer }
      else
        deny!
      end
    end

    def show?
      verify_permissions!('user.licenses.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if user.user?
        record.product == bearer
      in role: { name: 'user' } if user == bearer
        record.user == bearer
      else
        deny!
      end
    end
  end
end
