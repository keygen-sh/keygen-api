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
      role { build(:role, :admin) }
    end

    factory :developer do
      role { build(:role, :developer) }
    end

    factory :support_agent do
      role { build(:role, :support_agent) }
    end

    factory :sales_agent do
      role { build(:role, :sales_agent) }
    end

    factory :read_only do
      role { build(:role, :read_only) }
    end
  end
end
