# frozen_string_literal: true

FactoryBot.define do
  factory :release_platform, aliases: %i[platform] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT }) }

    sequence :key, %w[darwin linux windows].cycle

    account { NIL_ACCOUNT }
  end
end
