# frozen_string_literal: true

FactoryGirl.define do
  factory :release_entitlement_constraint do
    account nil
    entitlement nil
    release

    after :build do |constraint, evaluator|
      constraint.account     ||= evaluator.account.presence || create(:account)
      constraint.entitlement ||=
        evaluator.entitlement.presence || create(:entitlement, account: constraint.account)
    end
  end
end
