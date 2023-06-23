# frozen_string_literal: true

class RequestLogPolicy < ApplicationPolicy
  def index?
    verify_permissions!('request-log.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :environment)
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('request-log.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :environment)
      allow!
    else
      deny!
    end
  end

  def count? = allow? :show, record
end
