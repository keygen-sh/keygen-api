# frozen_string_literal: true

module Users
  class SecondFactorPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('user.second-factors.read')

      case bearer
      in role: { name: 'admin' }
        allow!
      in role: { name: 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'user' }
        record.all? { _1.user_id == bearer.id }
      else
        deny!
      end
    end

    def show?
      verify_permissions!('user.second-factors.read')

      case bearer
      in role: { name: 'admin' }
        allow!
      in role: { name: 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'user' }
        record.user_id == bearer.id
      else
        deny!
      end
    end

    def create?
      verify_permissions!('user.second-factors.create')

      # TODO(ezekg) Remove this and use permissions
      deny! if
        bearer.has_role?(:read_only)

      case bearer
      in role: { name: 'admin' }
        allow!
      in role: { name: 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'user' }
        record.user_id == bearer.id
      else
        deny!
      end
    end

    def update?
      verify_permissions!('user.second-factors.update')

      # TODO(ezekg) Remove this and use permissions
      deny! if
        bearer.has_role?(:read_only)

      case bearer
      in role: { name: 'admin' }
        allow!
      in role: { name: 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'user' }
        record.user_id == bearer.id
      else
        deny!
      end
    end

    def destroy?
      verify_permissions!('user.second-factors.delete')

      # TODO(ezekg) Remove this and use permissions
      deny! if
        bearer.has_role?(:read_only)

      case bearer
      in role: { name: 'admin' }
        allow!
      in role: { name: 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'user' }
        record.user_id == bearer.id
      else
        deny!
      end
    end
  end
end
