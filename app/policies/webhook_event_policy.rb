# frozen_string_literal: true

class WebhookEventPolicy < ApplicationPolicy
  def index?
    verify_permissions!('webhook-event.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'product' }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('webhook-event.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'product' }
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('webhook-event.delete')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def retry?
    verify_permissions!('webhook-event.retry')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end
end
