# frozen_string_literal: true

module Groups
  class GroupOwnerPolicy < ApplicationPolicy
    authorize :group

    def index?
      verify_permissions!('group.owners.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :product | :environment)
        allow!
      in role: Role(:user) if group.id == bearer.group_id || group.id.in?(bearer.group_ids)
        allow!
      in role: Role(:license) if group.id == bearer.group_id
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('group.owners.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :product | :environment)
        allow!
      in role: Role(:user) if group.id == bearer.group_id || group.id.in?(bearer.group_ids)
        allow!
      in role: Role(:license) if group.id == bearer.group_id
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('group.owners.attach')
      verify_environment!(
        # NOTE(ezekg) This seems weird, but we want to allow attaching global entitlements
        #             to shared groups, but not vice-versa. Essentially, we're checking
        #             for read permissions before inserting rows in the join table.
        strict: group.environment.nil?,
      )

      case bearer
      in role: Role(:admin | :developer | :product | :environment)
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('group.owners.detach')
      verify_environment!(
        # NOTE(ezekg) ^^^ ditto above except for detaching.
        strict: group.environment.nil?,
      )

      case bearer
      in role: Role(:admin | :developer | :product | :environment)
        allow!
      else
        deny!
      end
    end
  end
end
