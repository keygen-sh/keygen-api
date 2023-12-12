# frozen_string_literal: true

FactoryBot.define do
  factory :machine do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    fingerprint { SecureRandom.hex(12).upcase.scan(/.{2}/).join ":" }
    name        { Faker::Company.buzzword }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    license     { build(:license, account:, environment:) }

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

    trait :alive do
      last_heartbeat_at { Time.current }
    end

    trait :idle do
      last_heartbeat_at { nil }
    end

    trait :dead do
      last_heartbeat_at { 1.day.ago }
    end
  end
end
