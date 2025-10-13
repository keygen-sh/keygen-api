# frozen_string_literal: true

class WebhookEventPolicy < ApplicationPolicy
  def index?
    verify_permissions!('webhook-event.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :environment)
      allow!
    in role: Role(:product) if record.all? { it.product == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('webhook-event.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('webhook-event.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    else
      deny!
    end
  end

  def retry?
    verify_permissions!('webhook-event.retry')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    else
      deny!
    end
  end
end
