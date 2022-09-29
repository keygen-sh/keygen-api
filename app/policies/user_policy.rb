# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[create?]

  def index?
    verify_permissions!('user.read', *role_permissions_for(action: 'read'))

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all?(&:user?)
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('user.read', *role_permissions_for(action: 'read'))

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.user?
      allow!
    in role: { name: 'user' } if record == bearer
      allow!
    in role: { name: 'license' } if record == bearer.user
      ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
    else
      deny!
    end
  end

  def create?
    verify_permissions!('user.create', *role_permissions_for(action: 'create'))
    verify_privileges!

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.user?
      allow!
    in nil
      !account.protected?
    else
      deny!
    end
  end

  def update?
    verify_permissions!('user.update', *role_permissions_for(action: 'update'))
    verify_privileges!

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.user?
      allow!
    in role: { name: 'user' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('user.delete', *role_permissions_for(action: 'delete'))
    verify_privileges!

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def invite?
    verify_permissions!('user.invite', *role_permissions_for(action: 'invite'))

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    else
      deny!
    end
  end

  def ban?
    verify_permissions!('user.ban')

    deny! 'must have a user role' unless
      record.user?

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' }
      allow!
    else
      deny!
    end
  end

  def unban?
    verify_permissions!('user.unban')

    deny! 'must have a user role' unless
      record.user?

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' }
      allow!
    else
      deny!
    end
  end

  def me?
    verify_permissions!('user.read')

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
    when ENV.key?('KEYGEN_ENABLE_PERMISSIONS') &&
         bearer.role <= record.role && bearer.cannot?(*record.permissions.pluck(:action))
      deny! "#{whatami} lacks privileges to perform action on user" unless bearer.root?
    # Assert that user role escalation is not occurring by the bearer
    when bearer.role < record.role
      deny! "#{whatami} lacks privileges to perform action on user"
    end
  end
end
