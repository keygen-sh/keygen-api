# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    initialize_with { new(**attributes.reject { DEFAULT_ENVIRONMENT == _2 }) }

    name { Faker::App.name }
    platforms {
      [
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation
      ]
    }

    account     { nil }
    environment { DEFAULT_ENVIRONMENT }

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
      after :create do |product|
        product.environment = nil
        product.save!(validate: false)
      end
    end

    trait :global do
      in_nil_environment
    end
  end
end
