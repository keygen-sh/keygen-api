# frozen_string_literal: true

FactoryBot.define do
  factory :request_log do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    account     { Current.account }
    environment { Current.environment || NIL_ENVIRONMENT }
    requestor   { build(:admin, account:, environment:) }
    resource    { build(:artifact, account:, environment:) }

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
