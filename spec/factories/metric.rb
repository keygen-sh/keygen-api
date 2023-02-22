# frozen_string_literal: true

FactoryBot.define do
  factory :metric do
    initialize_with { new(**attributes) }

    data {{ data: { foo: 'bar' } }}

    event_type
  end
end
