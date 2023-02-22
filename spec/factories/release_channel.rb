# frozen_string_literal: true

FactoryBot.define do
  factory :release_channel, aliases: %i[channel] do
    initialize_with { new(**attributes) }

    sequence :key, %w[stable rc beta alpha dev].cycle

    account { nil }
  end
end
