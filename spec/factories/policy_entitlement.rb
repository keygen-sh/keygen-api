# frozen_string_literal: true

FactoryBot.define do
  factory :policy_entitlement do
    # Prevent duplicates due to cyclic entitlement codes.
    initialize_with { PolicyEntitlement.find_or_initialize_by(entitlement_id: entitlement&.id, policy_id: policy&.id) }

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
