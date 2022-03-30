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

    account { nil }

    after :build do |product, evaluator|
      account = evaluator.account.presence || create(:account)

      product.assign_attributes(
        account: account
      )
    end

    after :create do |product|
      product.role = create :role, :product, resource: product
      create :token, bearer: product
    end
  end
end
