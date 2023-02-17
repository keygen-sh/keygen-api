# frozen_string_literal: true

class ReleaseArchPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[index? show?]

  scope_for :active_record_relation do |relation|
    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'sales_agent' | 'support_agent' }
      relation.all
    in role: { name: 'product' } if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: { name: 'license' } if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
    in role: { name: 'user' } if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
    else
      relation.open
    end
  end

  def index?
    verify_permissions!('arch.read')

    allow!
  end

  def show?
    verify_permissions!('arch.read')

    allow!
  end
end
