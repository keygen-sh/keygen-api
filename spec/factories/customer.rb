# frozen_string_literal: true

FactoryBot.define do
  Stripe::Customer.send :alias_method, :save!, :save

  factory :customer, class: Stripe::Customer do
    initialize_with { new(**attributes) }

    email { Faker::Internet.safe_email }

    trait :with_card do
      source { StripeHelper.generate_card_token(last4: "4242", exp_month: 1, exp_year: 2552) }
    end
  end
end
