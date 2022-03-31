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
      product.account ||= evaluator.account.presence
    end

    after :create do |product|
      product.role = create :role, :product, resource: product
      create :token, bearer: product
    end
  end
end
