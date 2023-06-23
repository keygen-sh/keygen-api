# frozen_string_literal: true

class MetricPolicy < ApplicationPolicy
  def index?
    verify_permissions!('metric.read')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('metric.read')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
      allow!
    else
      deny!
    end
  end

  def count? = allow? :show, record
end
