# frozen_string_literal: true

FactoryGirl.define do
  factory :webhook_endpoint do
    url { "https://#{SecureRandom.hex}.example" }
  end
end
