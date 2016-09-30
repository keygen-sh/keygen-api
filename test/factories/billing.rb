FactoryGirl.define do
  factory :billing do
    external_customer_id Faker::Internet.password
    external_subscription_id Faker::Internet.password
    external_subscription_status "active"
  end
end
