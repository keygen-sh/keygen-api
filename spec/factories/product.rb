# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { Faker::App.name }
    platforms {
      [
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation
      ]
    }

    account { nil }

    after :build do |product, evaluator|
      product.account ||= evaluator.account.presence
    end

    trait :licensed do
      after :build do |product, evaluator|
        product.distribution_strategy = 'LICENSED'
      end
    end

    trait :open do
      after :build do |product, evaluator|
        product.distribution_strategy = 'OPEN'
      end
    end

    trait :closed do
      after :build do |product, evaluator|
        product.distribution_strategy = 'CLOSED'
      end
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
