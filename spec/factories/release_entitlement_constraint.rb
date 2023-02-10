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
