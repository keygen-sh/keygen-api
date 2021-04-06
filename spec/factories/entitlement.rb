# frozen_string_literal: true

FactoryGirl.define do
  factory :entitlement do
    code { "#{Faker::Company.buzzword.parameterize.underscore}_#{SecureRandom.hex(2)}".upcase }
    name { Faker::Company.industry }
  end
end
