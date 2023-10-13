# frozen_string_literal: true

FactoryBot.define do
  factory :event_type do
    initialize_with { EventType.find_by(event:) || new(**attributes) }

    event { "test.event.#{SecureRandom.hex}" }
  end
end
