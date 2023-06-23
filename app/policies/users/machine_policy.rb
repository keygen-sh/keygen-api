# frozen_string_literal: true

module Users
  class MachinePolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('machine.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if user.user?
        record.all? { _1.product == bearer }
      in role: Role(:user) if user == bearer
        record.all? { _1.user == bearer }
      else
        deny!
      end
    end

    def show?
      verify_permissions!('machine.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if user.user?
        record.product == bearer
      in role: Role(:user) if user == bearer
        record.user == bearer
      else
        deny!
      end
    end
  end
end
