# frozen_string_literal: true

FactoryGirl.define do
  factory :event_type do
    event { "test.event.#{SecureRandom.hex}" }
  end
end
