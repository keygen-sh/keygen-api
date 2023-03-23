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

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      environment { nil }
    end

    trait :global do
      in_nil_environment
    end
  end
end
