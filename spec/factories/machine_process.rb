# frozen_string_literal: true

FactoryBot.define do
  factory :machine_process, aliases: %i[process] do
    pid { SecureRandom.hex(12) }

    account { nil }
    machine { nil }

    after :build do |process, evaluator|
      process.account ||= evaluator.account.presence
      process.machine ||= evaluator.machine.presence || build(:machine, account: process.account)
    end
  end
end
