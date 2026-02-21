# frozen_string_literal: true

FactoryBot.define do
  factory :request_log do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    requestor   { build(:admin, account:, environment:) }
    resource    { build(:artifact, account:, environment:) }

    # HACK(ezekg) sometimes we create logs in the past but that causes clickhouse
    #             to immediately throw out the records during merge because our
    #             table by default only keeps records for 30 days
    ttl { 100.years }

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
