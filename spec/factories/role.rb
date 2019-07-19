# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    resource { nil }

    trait :user do
      name { :user }
    end

    trait :admin do
      name { :admin }
    end

    trait :product do
      name { :product }
    end
  end
end
