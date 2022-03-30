# frozen_string_literal: true

FactoryBot.define do
  factory :event_type do
    event { "test.event.#{SecureRandom.hex}" }
  end
end
