# frozen_string_literal: true

FactoryBot.define do
  factory :release_artifact do
    key { SecureRandom.hex }

    account { nil }
    product { nil }
    release

    after :build do |artifact, evaluator|
      artifact.account ||= evaluator.account.presence || create(:account)
      artifact.product ||= evaluator.product.presence || create(:product, account: artifact.account)
      artifact.release ||= evaluator.release.presence || create(:release)
    end
  end
end
