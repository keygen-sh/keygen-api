# frozen_string_literal: true

class EventLogPolicy < ApplicationPolicy
  def index?
    verify_permissions!('event-log.read')

    deny! unless
      account.ent_tier?

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('event-log.read')

    deny! unless
      account.ent_tier?

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' }
      allow!
    else
      deny!
    end
  end

  def count? = allow? :show
end
