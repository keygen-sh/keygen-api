# frozen_string_literal: true

module Users
  class SecondFactorPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('user.second-factors.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin)
        allow!
      in role: Role(:developer | :sales_agent | :support_agent | :read_only | :user)
        record.all? { it.user_id == bearer.id }
      else
        deny!
      end
    end

    def show?
      verify_permissions!('user.second-factors.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin)
        allow!
      in role: Role(:developer | :sales_agent | :support_agent | :read_only | :user)
        record.user_id == bearer.id
      else
        deny!
      end
    end

    def create?
      verify_permissions!('user.second-factors.create')
      verify_environment!

      # TODO(ezekg) Remove this and use permissions
      deny! if
        bearer.has_role?(:read_only)

      case bearer
      in role: Role(:admin)
        allow!
      in role: Role(:developer | :sales_agent | :support_agent | :read_only | :user)
        record.user_id == bearer.id
      else
        deny!
      end
    end

    def update?
      verify_permissions!('user.second-factors.update')
      verify_environment!

      # TODO(ezekg) Remove this and use permissions
      deny! if
        bearer.has_role?(:read_only)

      case bearer
      in role: Role(:admin)
        allow!
      in role: Role(:developer | :sales_agent | :support_agent | :read_only | :user)
        record.user_id == bearer.id
      else
        deny!
      end
    end

    def destroy?
      verify_permissions!('user.second-factors.delete')
      verify_environment!

      # TODO(ezekg) Remove this and use permissions
      deny! if
        bearer.has_role?(:read_only)

      case bearer
      in role: Role(:admin)
        allow!
      in role: Role(:developer | :sales_agent | :support_agent | :read_only | :user)
        record.user_id == bearer.id
      else
        deny!
      end
    end
  end
end
