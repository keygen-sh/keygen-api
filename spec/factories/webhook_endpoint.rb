FactoryGirl.define do
  factory :webhook_endpoint do
    url { "https://#{SecureRandom.hex}.com" }
  end
end
