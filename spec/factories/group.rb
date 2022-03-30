# frozen_string_literal: true

FactoryBot.define do
  factory :group do
    name { Faker::Company.name }
  end
end
