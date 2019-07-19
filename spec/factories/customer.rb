# frozen_string_literal: true

FactoryBot.define do
  Stripe::Customer.send :alias_method, :save!, :save

  factory :customer, class: Stripe::Customer do
    email { Faker::Internet.safe_email }

    trait :with_card do
      source { StripeHelper.generate_card_token }
    end
  end
end
