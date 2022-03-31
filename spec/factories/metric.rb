# frozen_string_literal: true

FactoryBot.define do
  factory :metric do
    data {
      { data: { foo: 'bar' } }
    }

    event_type
  end
end
