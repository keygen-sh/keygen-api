# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    slug { [Faker::Internet.domain_word, SecureRandom.hex].join }

    before :create do |account|
      account.users << build(:admin, account: account)
      account.billing = build(:billing, account: account)
      account.plan = create(:plan)
    end
  end
end
