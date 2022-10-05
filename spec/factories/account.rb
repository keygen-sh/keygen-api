# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    slug { [Faker::Internet.domain_name.parameterize, SecureRandom.hex(4)].join('-') }
    name { Faker::Company.name }

    billing { nil }
    plan

    after :build do |account|
      account.billing = build(:billing, account:)
      account.users << build(:admin, account:)
    end

    trait :std do
      before :create do |account|
        account.plan = build(:plan, :std)
      end
    end

    trait :ent do
      before :create do |account|
        account.plan = build(:plan, :ent)
      end
    end

    trait :unprotected do
      protected { false }
    end

    trait :protected do
      protected { true }
    end
  end
end
