# frozen_string_literal: true

FactoryBot.define do
  factory :environment do
    # Prevent duplicates due to recurring environment codes. Attempting
    # to insert duplicate codes would fail, and this prevents that.
    initialize_with { Environment.find_by(code:) || new(**attributes) }

    isolation_strategy { 'ISOLATED' }
    code               { SecureRandom.hex(4) }
    name               { code.humanize }

    trait :isolated do
      isolation_strategy { 'ISOLATED' }
      code               { 'isolated' }
    end

    trait :shared do
      isolation_strategy { 'SHARED' }
      code               { 'shared' }
    end
  end
end
