# frozen_string_literal: true

FactoryBot.define do
  factory :key do
    key { SecureRandom.hex(12).upcase.scan(/.{4}/).join "-" }

    account { nil }
    policy { nil }

    after :build do |key, evaluator|
      key.account ||= evaluator.account.presence
      key.policy  ||= evaluator.policy.presence || build(:policy, :pooled, account: key.account)
    end
  end
end
