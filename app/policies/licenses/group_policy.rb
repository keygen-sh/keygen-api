# frozen_string_literal: true

module Licenses
  class GroupPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('license.group.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer || record.id == bearer.group_id || record.id.in?(bearer.group_ids)
        allowed_to? :show?, record, with: ::GroupPolicy
      in role: { name: 'license' } if license == bearer
        allowed_to? :show?, record, with: ::GroupPolicy
      else
        deny!
      end
    end

    def update?
      verify_permissions!('license.group.update')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
