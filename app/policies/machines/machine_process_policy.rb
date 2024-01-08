# frozen_string_literal: true

module Machines
  class MachineProcessPolicy < ApplicationPolicy
    authorize :machine

    def index?
      verify_permissions!('process.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      in role: Role(:user) if machine.owner == bearer
        allow!
      in role: Role(:license) if machine.license == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('process.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      in role: Role(:user) if machine.owner == bearer
        allow!
      in role: Role(:license) if machine.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end
