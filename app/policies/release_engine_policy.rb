# frozen_string_literal: true

class ReleaseEnginePolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[index? show?]

  scope_for :active_record_relation do |relation|
    relation.all
  end

  def index?
    verify_permissions!('engine.read')
    verify_environment!(
      strict: false,
    )

    allow!
  end

  def show?
    verify_permissions!('engine.read')
    verify_environment!(
      strict: false,
    )

    allow!
  end
end
