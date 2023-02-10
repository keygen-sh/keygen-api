# frozen_string_literal: true

FactoryBot.define do
  factory :second_factor do
    account { nil }
    user { nil }

    after :build do |second_factor, evaluator|
      account = evaluator.account.presence
      user =
        if evaluator.user.present?
          evaluator.user
        else
          build(:user, account: account)
        end

      second_factor.assign_attributes(
        account: user.account,
        user: user
      )
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
