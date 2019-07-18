# frozen_string_literal: true

FactoryGirl.define do
  factory :billing do
    customer_id { Faker::Internet.password }
    subscription_id { Faker::Internet.password }
    subscription_status { "active" }
    card_brand { "Visa" }
    card_last4 { "4242" }
    card_expiry { 1.year.from_now.to_s }
    state { "subscribed" }
  end
end
