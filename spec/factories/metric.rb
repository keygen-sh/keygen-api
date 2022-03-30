# frozen_string_literal: true

FactoryBot.define do
  factory :metric do
    association :event_type

    data {
      { data: { foo: 'bar' } }
    }
  end
end
