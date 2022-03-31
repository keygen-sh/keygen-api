# frozen_string_literal: true

FactoryBot.define do
  factory :release_filetype, aliases: %i[filetype] do
    name { 'DMG' }
    key { 'dmg' }

    account { nil }

    after :build do |filetype, evaluator|
      filetype.account ||= evaluator.account.presence
    end
  end
end
