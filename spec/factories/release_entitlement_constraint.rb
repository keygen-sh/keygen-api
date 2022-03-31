# frozen_string_literal: true

FactoryBot.define do
  factory :release_entitlement_constraint, aliases: %i[constraint] do
    account { nil }
    entitlement { nil }
    release { nil }

    after :build do |constraint, evaluator|
      constraint.account     ||= evaluator.account.presence
      constraint.entitlement ||=
        evaluator.entitlement.presence || build(:entitlement, account: constraint.account)
    end
  end
end
