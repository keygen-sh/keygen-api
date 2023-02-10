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

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      environment { nil }
    end

    trait :global do
      in_nil_environment
    end
  end
end
