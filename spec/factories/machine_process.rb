# frozen_string_literal: true

FactoryBot.define do
  factory :machine_process, aliases: %i[process] do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    pid { SecureRandom.hex(12) }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    machine     { build(:machine, account:, environment:) }

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

    trait :dead do
      last_heartbeat_at { 1.day.ago }
    end
  end
end
