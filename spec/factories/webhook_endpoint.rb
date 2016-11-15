FactoryGirl.define do
  factory :webhook_endpoint do
    url { Faker::Internet.url }
  end
end
