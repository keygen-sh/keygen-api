# frozen_string_literal: true

FactoryBot.define do
  factory :metric do
    association :event_type

    metric { "test.metric" }
    data {
      { data: { foo: 'bar' } }
    }
  end
end
