# frozen_string_literal: true

class ReleaseChannelPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[index? show?]

  scope_for :active_record_relation do |relation|
    relation = relation.for_environment(environment, strict: environment.nil?) if
      relation.respond_to?(:for_environment)

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
      relation.all
    in role: Role(:environment) if relation.respond_to?(:for_environment)
      relation.for_environment(bearer.id)
    in role: Role(:product) if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: Role(:license) if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
    in role: Role(:user) if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
    else
      relation.open
    end
  end

  def index?
    verify_permissions!('channel.read')
    verify_environment!(
      strict: false,
    )

    allow!
  end

  def show?
    verify_permissions!('channel.read')
    verify_environment!(
      strict: false,
    )

    allow!
  end
end
