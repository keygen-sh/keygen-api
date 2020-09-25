# frozen_string_literal: true

FactoryGirl.define do
  factory :webhook_event do
    association :event_type

    event { "test.event" }
    endpoint { Faker::Internet.url }
    payload { { payload: "payload" }.to_json }
    jid { SecureRandom.hex }
  end
end
