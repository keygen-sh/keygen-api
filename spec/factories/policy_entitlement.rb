# frozen_string_literal: true

FactoryGirl.define do
  factory :policy_entitlement do
    account nil
    entitlement nil
    policy

    after :build do |policy_entitlement, evaluator|
      policy_entitlement.account     ||= evaluator.account.presence || create(:account)
      policy_entitlement.entitlement ||=
        evaluator.entitlement.presence || create(:entitlement, account: policy_entitlement.account)
    end
  end
end
