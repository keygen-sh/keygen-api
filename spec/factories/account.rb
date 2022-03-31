# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    slug { Faker::Internet.domain_name.parameterize }

    billing { nil }
    plan

    after :build do |account|
      account.billing = build(:billing, account: account)
      account.users << build(:admin, account: account)
    end
  end
end
