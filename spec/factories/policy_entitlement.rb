# frozen_string_literal: true

FactoryBot.define do
  factory :policy_entitlement do
    account { nil }
    entitlement { nil }
    policy { nil }

    after :build do |policy_entitlement, evaluator|
      policy_entitlement.account     ||= evaluator.account.presence
      policy_entitlement.entitlement ||=
        evaluator.entitlement.presence || build(:entitlement, account: policy_entitlement.account)
    end
  end
end
