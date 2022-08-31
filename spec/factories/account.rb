# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    slug { [Faker::Internet.domain_name.parameterize, SecureRandom.hex(4)].join('-') }
    name { Faker::Company.name }

    billing { nil }
    plan

    after :build do |account|
      account.billing = build(:billing, account: account)
      account.users << build(:admin, account: account)
    end

    trait :unprotected do
      protected { false }
    end

    trait :protected do
      protected { true }
    end
  end
end
