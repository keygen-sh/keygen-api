# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_endpoint do
    url { "https://#{SecureRandom.hex}.example" }

    account { nil }
  end
end
