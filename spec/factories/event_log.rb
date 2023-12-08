# frozen_string_literal: true

FactoryBot.define do
  factory :event_log do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    account     { Current.account }
    environment { Current.environment || NIL_ENVIRONMENT }
    resource    { build(:license, account:, environment:) }
    whodunnit   { build(:user, account:, environment:) }
    event_type

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
