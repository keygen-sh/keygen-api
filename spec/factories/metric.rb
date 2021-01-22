# frozen_string_literal: true

FactoryGirl.define do
  factory :metric do
    association :event_type

    data {
      { data: { foo: 'bar' } }
    }
  end
end
