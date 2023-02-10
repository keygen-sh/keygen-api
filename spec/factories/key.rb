# frozen_string_literal: true

FactoryBot.define do
  factory :key do
    key { SecureRandom.hex(12).upcase.scan(/.{4}/).join "-" }

    account { nil }
    policy { nil }

    after :build do |key, evaluator|
      key.account ||= evaluator.account.presence
      key.policy  ||= evaluator.policy.presence || build(:policy, :pooled, account: key.account)
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
