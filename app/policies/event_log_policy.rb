# frozen_string_literal: true

class EventLogPolicy < ApplicationPolicy
  def index?
    verify_permissions!('event-log.read')
    verify_environment!(
      strict: false,
    )

    deny! unless
      account.ent?

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('event-log.read')
    verify_environment!(
      strict: false,
    )

    deny! unless
      account.ent?

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' }
      allow!
    else
      deny!
    end
  end

  def count? = allow? :show, record
end
