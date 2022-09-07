# frozen_string_literal: true

FactoryBot.define do
  factory :release_filetype, aliases: %i[filetype] do
    sequence :key, %w[dmg exe zip tar.gz appimage].cycle

    account { nil }

    after :build do |filetype, evaluator|
      filetype.account ||= evaluator.account.presence
    end
  end
end
