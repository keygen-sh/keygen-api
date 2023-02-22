# frozen_string_literal: true

FactoryBot.define do
  factory :event_type do
    initialize_with { new(**attributes) }

    event { "test.event.#{SecureRandom.hex}" }
  end
end
