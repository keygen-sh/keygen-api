FactoryGirl.define do
  factory :billing do
    customer_id Faker::Internet.password
    subscription_id Faker::Internet.password
    subscription_status "active"
    state "subscribed"
  end
end
