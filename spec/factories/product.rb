# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { Faker::App.name }
    platforms {
      [
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation
      ]
    }

    association :account

    after :build do |product, evaluator|
      account = evaluator.account or create :account

      product.assign_attributes(
        account: account
      )
    end

    after :create do |product|
      create :role, :product, resource: product
      create :token, bearer: product
    end
  end
end
