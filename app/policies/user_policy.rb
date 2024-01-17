# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[create?]

  def index?
    verify_permissions!('user.read', *role_permissions_for(action: 'read'))
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
      allow!
    in role: Role(:product | :environment) if record.all?(&:user?)
      allow!
    in role: Role(:user) if record.all? { _1 == bearer || _1.id.in?(bearer.teammate_ids) }
      allow!
    in role: Role(:license) if record_ids & bearer.user_ids == record_ids
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('user.read', *role_permissions_for(action: 'read'))
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
      allow!
    in role: Role(:product | :environment) if record.user?
      allow!
    in role: Role(:user) if record == bearer || record_id.in?(bearer.teammate_ids)
      allow!
    in role: Role(:license) if record == bearer.owner || record_id.in?(bearer.user_ids)
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('user.create', *role_permissions_for(action: 'create'))
    verify_environment!
    verify_privileges!

    case bearer
    in role: Role(:admin | :developer)
      allow!
    in role: Role(:product | :environment) if record.user?
      allow!
    in nil
      !account.protected?
    else
      deny!
    end
  end

  def update?
    verify_permissions!('user.update', *role_permissions_for(action: 'update'))
    verify_environment!
    verify_privileges!

    case bearer
    in role: Role(:admin | :developer | :sales_agent)
      allow!
    in role: Role(:product | :environment) if record.user?
      allow!
    in role: Role(:user) if record == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('user.delete', *role_permissions_for(action: 'delete'))
    verify_environment!
    verify_privileges!

    case bearer
    in role: Role(:admin | :developer)
      allow!
    in role: Role(:environment) if record.user?
      allow!
    else
      deny!
    end
  end

  def invite?
    verify_permissions!('user.invite', *role_permissions_for(action: 'invite'))
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent)
      allow!
    in role: Role(:environment) if record.user?
      allow!
    else
      deny!
    end
  end

  def ban?
    verify_permissions!('user.ban')
    verify_environment!

    deny! 'must have a user role' unless
      record.user?

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :product | :environment)
      allow!
    else
      deny!
    end
  end

  def unban?
    verify_permissions!('user.unban')
    verify_environment!

    deny! 'must have a user role' unless
      record.user?

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :product | :environment)
      allow!
    else
      deny!
    end
  end

  def me?
    verify_permissions!('user.read')
    verify_environment!(
      strict: false,
    )

    record == bearer
  end

  private

  def role_permissions_for(action:)
    perms = []

    perms << "admin.#{action}" if
      record.respond_to?(:any?) ? record.any?(&:admin?) : record.admin?

    perms
  end

  def verify_privileges!
    return if
      record.nil? || record.role.nil?

    # Assert that privilege escalation is not occurring by anonymous (sanity check)
    deny! 'anon lacks privileges to perform action on user' if
      bearer.nil? && record.role.changed? && !record.role.user?

    return if
      bearer.nil?

    case
    # Assert that user permission escalation is not occurring by the bearer.
    # Bearers can only assign permissions that they themselves have, unless
    # they're a root admin, or their role is greater.
    when !bearer.root? && bearer.role == record.role &&
          bearer.cannot?(*record.permissions.actions)
      deny! "#{whatami} lacks privileges to perform action on user"
    # Assert that user role escalation is not occurring by the bearer by
    # creating a user with a greater role than theirs.
    when bearer.role < record.role
      deny! "#{whatami} lacks privileges to perform action on user"
    end
  end
end
