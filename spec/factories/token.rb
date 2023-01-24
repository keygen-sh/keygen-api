# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    account { nil }
    bearer { nil }

    after :build do |token, evaluator|
      account = evaluator.account.presence
      bearer =
        if evaluator.bearer.present?
          evaluator.bearer
        else
          build(:user, account: account)
        end

      token.assign_attributes(
        digest: "test_#{SecureRandom.hex}",
        account: bearer.account,
        bearer: bearer,
      )
    end

    trait :in_isolated_environment do
      after :create do |token|
        token.update(environment: build(:environment, :isolated, account: token.account))
      end
    end

    trait :in_shared_environment do
      after :create do |token|
        token.update(environment: build(:environment, :shared, account: token.account))
      end
    end

    trait :in_nil_environment do
      after :create do |token|
        token.update(environment: nil)
      end
    end
  end
end
