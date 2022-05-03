# frozen_string_literal: true

FactoryBot.define do
  factory :release do
    name { Faker::App.name }
    version { nil }

    account { nil }
    product { nil }
    artifacts { [] }
    channel { nil }

    draft

    after :build do |release, evaluator|
      release.account  ||= evaluator.account.presence
      release.product  ||= evaluator.product.presence || build(:product, account: release.account)
      release.channel  ||= evaluator.channel.presence || build(:channel, account: release.account)

      # Add build tag so that there's no chance for collisions
      release.version ||=
        if release.channel.pre_release?
          "#{Faker::App.semantic_version}-#{release.channel.key}+build.#{Time.current.to_f}"
        else
          "#{Faker::App.semantic_version}+build.#{Time.current.to_f}"
        end
    end

    trait :draft do
      after :build do |release, evaluator|
        release.status = 'DRAFT'
        release.artifacts = []
      end
    end

    trait :published do
      after :build do |release, evaluator|
        release.status = 'PUBLISHED'
        release.artifacts << build(:release_artifact,
          account: release.account,
          product: release.product,
          release: release,
        )
      end
    end
  end
end
