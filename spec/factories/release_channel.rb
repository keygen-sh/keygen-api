# frozen_string_literal: true

FactoryBot.define do
  factory :release_channel, aliases: %i[channel] do
    name { key.capitalize }
    key { "stable" }

    account { nil }

    after :build do |channel, evaluator|
      channel.account ||= evaluator.account.presence
    end
  end
end
