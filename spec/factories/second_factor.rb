# frozen_string_literal: true

FactoryBot.define do
  factory :second_factor do
    account     { nil }
    environment { nil }
    user        { build(:user, account:, environment:) }

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
      after :create do |mfa|
        mfa.environment = nil
        mfa.save!(validate: false)
      end
    end
    trait :global do
      in_nil_environment
    end
  end
end
