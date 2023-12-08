# frozen_string_literal: true

FactoryBot.define do
  factory :release_platform, aliases: %i[platform] do
    initialize_with { new(**attributes) }

    sequence :key, %w[darwin linux windows].cycle

    account { Current.account }
  end
end
