# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_event do
    endpoint { Faker::Internet.url }
    payload { { payload: "payload" }.to_json }
    jid { SecureRandom.hex }

    account { nil }
    event_type
  end
end
