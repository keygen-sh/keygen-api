# frozen_string_literal: true

FactoryBot.define do
  factory :request_log do
    initialize_with { new(**attributes) }

    account     { nil }
    environment { nil }

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
      after :create do |log|
        log.environment = nil
        log.save!(validate: false)
      end
    end

    trait :global do
      in_nil_environment
    end
  end
end
