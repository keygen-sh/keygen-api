# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.name }
    last_name { Faker::Name.name }
    email { [SecureRandom.hex(4), Faker::Internet.safe_email].join('') }
    password { "password" }

    account { nil }

    after :build do |user, evaluator|
      user.account ||= evaluator.account.presence
    end

    factory :admin do
      after :create do |user|
        user.grant_role!(:admin)
      end
    end

    factory :developer do
      after :create do |user|
        user.grant_role!(:developer)
      end
    end

    factory :support_agent do
      after :create do |user|
        user.grant_role!(:support_agent)
      end
    end

    factory :sales_agent do
      after :create do |user|
        user.grant_role!(:sales_agent)
      end
    end

    factory :read_only do
      after :create do |user|
        user.grant_role!(:read_only)
      end
    end
  end
end
