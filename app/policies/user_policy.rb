# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[create?]

  def index?
    verify_permissions!('user.read')

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
    verify_permissions!('user.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.user?
      allow!
    in role: { name: 'user' } if record == bearer
      allow!
    in role: { name: 'license' } if record == bearer.user
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('user.create')
    verify_role!(record)

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
    verify_permissions!('user.update')
    verify_role!(record)

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
    verify_permissions!('user.delete')
    verify_role!(record)

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def invite?
    verify_permissions!('user.invite')

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

  def verify_role!(user)
    return if
      user.nil? || user.role.nil?

    # Assert that privilege escalation is not occurring by anonymous (sanity check)
    deny! 'anonymous is attempting to escalate privileges for the user' if
      bearer.nil? && user.role.changed? && !user.role.user?

    return if
      bearer.nil?

    # Assert that privilege escalation is not occurring by a bearer (sanity check)
    deny! "#{whatami} is attempting to escalate privileges for the user" if
      (bearer.role.changed? || user.role.changed?) &&
      bearer.role < user.role

    # Assert bearer can perform this action on the user
    deny! "#{whatami} lacks privileges to perform action on user" if
      bearer.role < user.role
  end
end
