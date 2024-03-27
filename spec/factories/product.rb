# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    name { Faker::App.name }
    platforms {
      [
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation
      ]
    }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    trait :licensed do
      distribution_strategy { 'LICENSED' }
    end

    trait :open do
      distribution_strategy { 'OPEN' }
    end

    trait :closed do
      distribution_strategy { 'CLOSED' }
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
