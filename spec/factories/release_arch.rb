# frozen_string_literal: true

FactoryBot.define do
  factory :release_arch, aliases: %i[arch] do
    name { 'Apple Sillicon' }
    key { 'amd64' }

    account { nil }

    after :build do |platform, evaluator|
      platform.account ||= evaluator.account.presence
    end
  end
end
