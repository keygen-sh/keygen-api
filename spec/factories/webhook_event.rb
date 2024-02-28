# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_event do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    endpoint { Faker::Internet.url }
    payload  { '{}' }
    jid      { SecureRandom.hex }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    event_type

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
