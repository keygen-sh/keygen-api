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
      before :create do |product|
        product.update(environment: build(:environment, :isolated, account: product.account))
      end
    end

    trait :in_shared_environment do
      before :create do |product|
        product.update(environment: build(:environment, :shared, account: product.account))
      end
    end

    trait :in_nil_environment do
      before :create do |product|
        product.update(environment: nil)
      end
    end
  end
end
