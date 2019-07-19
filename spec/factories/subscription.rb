# frozen_string_literal: true

FactoryBot.define do
  Stripe::Subscription.send :alias_method, :save!, :save

  factory :subscription, class: Stripe::Subscription do
    customer { create(:customer).id }
    plan { nil }
  end
end
