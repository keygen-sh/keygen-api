# frozen_string_literal: true

FactoryBot.define do
  factory :event_log do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    resource    { build(:license, account:, environment:) }
    whodunnit   { nil }
    event_type

    # HACK(ezekg) sometimes we create logs in the past but that causes clickhouse
    #             to immediately throw out the records during merge because our
    #             table by default only keeps records for 30 days
    ttl { 100.years }

    trait :license_validation_succeeded do
      event_type { build(:event_type, event: 'license.validation.succeeded') }
    end

    trait :license_validation_failed do
      event_type { build(:event_type, event: 'license.validation.failed') }
    end

    trait :machine_heartbeat_ping do
      event_type { build(:event_type, event: 'machine.heartbeat.ping') }
    end

    trait :process_heartbeat_ping do
      event_type { build(:event_type, event: 'process.heartbeat.ping') }
    end

    trait :license_created do
      event_type { build(:event_type, event: 'license.created') }
    end

    trait :machine_created do
      event_type { build(:event_type, event: 'machine.created') }
    end

    trait :machine_deleted do
      event_type { build(:event_type, event: 'machine.deleted') }
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
