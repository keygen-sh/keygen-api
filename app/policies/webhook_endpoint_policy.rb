# frozen_string_literal: true

class WebhookEndpointPolicy < ApplicationPolicy
  def index?
    verify_permissions!('webhook-endpoint.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'product' }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('webhook-endpoint.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'product' }
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('webhook-endpoint.create')

    case bearer
    in role: { name: 'admin' | 'developer' | 'product' }
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('webhook-endpoint.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'product' }
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('webhook-endpoint.delete')

    case bearer
    in role: { name: 'admin' | 'developer' | 'product' }
      allow!
    else
      deny!
    end
  end
end
