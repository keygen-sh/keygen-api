# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    initialize_with { new(skip_slack_invite: true, skip_welcome_email: true, **attributes) }

    slug { "#{Faker::Internet.domain_name.parameterize}-#{SecureRandom.hex(4)}" }
    name { Faker::Company.name }

    billing { nil }
    plan

    after :build do |account|
      account.billing = build(:billing, account:)
      account.users << build(:admin, account:, environment: nil)
    end

    trait :std do
      plan { build(:plan, :std) }
    end

    trait :ent do
      plan { build(:plan, :ent) }
    end

    trait :unprotected do
      protected { false }
    end

    trait :protected do
      protected { true }
    end
  end
end
