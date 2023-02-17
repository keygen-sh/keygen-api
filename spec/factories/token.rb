# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    digest { "test_#{SecureRandom.hex}" }

    account     { nil }
    environment { nil }
    bearer      { build(:user, account:, environment:) }

    trait :in_isolated_environment do
      before :create do |token|
        token.update(environment: build(:environment, :isolated, account: token.account))
      end
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
