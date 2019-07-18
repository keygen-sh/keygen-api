# frozen_string_literal: true

FactoryGirl.define do
  factory :account do
    name { Faker::Company.name }
    slug { [Faker::Internet.domain_word, SecureRandom.hex].join }

    users []
    billing
    plan

    before :create do |account|
      account.users << build(:admin, account: account)
    end
  end
end
