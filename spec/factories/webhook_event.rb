# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_event do
    association :event_type

    endpoint { Faker::Internet.url }
    payload { { payload: "payload" }.to_json }
    jid { SecureRandom.hex }
  end
end
