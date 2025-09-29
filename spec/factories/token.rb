# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    digest { "test_#{SecureRandom.hex}" }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    bearer      { build(:user, account:, environment:) }

    trait :environment do
      bearer { build(:environment, account:) }
    end

    trait :product do
      bearer { build(:product, account:, environment:) }
    end

    trait :license do
      bearer { build(:license, account:, environment:) }
    end

    trait :admin do
      bearer { build(:admin, account:, environment:) }
    end

    trait :user do
      bearer { build(:user, account:, environment:) }
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
