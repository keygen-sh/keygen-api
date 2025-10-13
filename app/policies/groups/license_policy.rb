# frozen_string_literal: true

module Groups
  class LicensePolicy < ApplicationPolicy
    authorize :group

    scope_for :active_record_relation do |relation|
      relation = relation.for_environment(environment) if
        relation.respond_to?(:for_environment)

      case bearer
      in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
        relation.all
      in role: Role(:environment) if relation.respond_to?(:for_environment)
        relation.for_environment(bearer.id)
      in role: Role(:product) if relation.respond_to?(:for_product)
        relation.for_product(bearer.id)
      in role: Role(:user) if relation.respond_to?(:for_group_owner)
        relation.for_group_owner(bearer.id)
      else
        relation.none
      end
    end

    def index?
      verify_permissions!('group.licenses.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record.all? { it.product == bearer }
        allow!
      in role: Role(:user) if bearer.group_ids? && record.all? { it.group_id? && it.group_id.in?(bearer.group_ids) }
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('group.licenses.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record.product == bearer
        allow!
      in role: Role(:user) if bearer.group_ids? && record.group_id? && record.group_id.in?(bearer.group_ids)
        allow!
      else
        deny!
      end
    end
  end
end
