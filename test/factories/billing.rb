FactoryGirl.define do
  factory :billing do
    external_customer_id Faker::Internet.password
    status "active"
  end
end
