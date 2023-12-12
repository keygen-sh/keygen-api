# frozen_string_literal: true

FactoryBot.define do
  factory :release_channel, aliases: %i[channel] do
    initialize_with { ReleaseChannel.find_by(key:) || new(**attributes) }

    sequence :key, %w[stable rc beta alpha dev].cycle

    account { NIL_ACCOUNT }

    trait :stable do
      key { 'stable' }
    end

    trait :rc do
      key { 'rc' }
    end

    trait :beta do
      key { 'beta' }
    end

    trait :alpha do
      key { 'alpha' }
    end

    trait :dev do
      key { 'dev' }
    end
  end
end
