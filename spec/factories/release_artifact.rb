# frozen_string_literal: true

FactoryBot.define do
  factory :release_artifact, aliases: %i[artifact] do
    key { SecureRandom.hex }

    account { nil }
    product { nil }
    release { nil }

    after :build do |artifact, evaluator|
      artifact.account ||= evaluator.account.presence
      artifact.product ||= evaluator.product.presence || build(:product, account: artifact.account)
      artifact.release ||= evaluator.release.presence || build(:release, account: artifact.account)
    end
  end
end
