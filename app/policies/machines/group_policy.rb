# frozen_string_literal: true

module Machines
  class GroupPolicy < ApplicationPolicy
    authorize :machine

    def show?
      verify_permissions!('group.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      in role: Role(:user) if machine.owner == bearer || bearer.machines.exists?(machine.id) || record.id == bearer.group_id || record.id.in?(bearer.group_ids)
        allow!
      in role: Role(:license) if machine.license == bearer
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('machine.group.update')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
