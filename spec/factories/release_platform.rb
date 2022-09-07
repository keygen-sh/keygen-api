# frozen_string_literal: true

FactoryBot.define do
  factory :release_platform, aliases: %i[platform] do
    sequence :key, %w[darwin linux windows].cycle

    account { nil }

    after :build do |platform, evaluator|
      platform.account ||= evaluator.account.presence
    end
  end
end
