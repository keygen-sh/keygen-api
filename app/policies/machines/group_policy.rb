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
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if machine.product == bearer
        allow!
      in role: { name: 'user' } if machine.user == bearer || record.id == bearer.group_id || record.id.in?(bearer.group_ids)
        allow!
      in role: { name: 'license' } if machine.license == bearer
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('machine.group.update')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if machine.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
