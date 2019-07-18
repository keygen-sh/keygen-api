# frozen_string_literal: true

FactoryGirl.define do
  factory :metric do
    metric { "test.metric" }
    data { { data: "data" } }
  end
end
