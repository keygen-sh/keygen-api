# frozen_string_literal: true

FactoryBot.define do
  factory :release do
    name { Faker::App.name }
    filename { nil }
    filesize { Faker::Number.between(from: 0, to: 1.gigabyte.to_i) }
    version { nil }

    account { nil }
    product { nil }
    artifact { nil }
    platform { nil }
    filetype { nil }
    channel { nil }

    unpublished

    after :build do |release, evaluator|
      release.account  ||= evaluator.account.presence
      release.product  ||= evaluator.product.presence || build(:product, account: release.account)
      release.platform ||= evaluator.platform.presence || build(:platform, account: release.account)
      release.filetype ||= evaluator.filetype.presence || build(:filetype, account: release.account)
      release.channel  ||= evaluator.channel.presence || build(:channel, account: release.account)

      # Add build tag so that there's no chance for collisions
      release.version ||=
        if release.channel.pre_release?
          "#{Faker::App.semantic_version}-#{release.channel.key}+build.#{Time.current.to_f}"
        else
          "#{Faker::App.semantic_version}+build.#{Time.current.to_f}"
        end

      # Add dependant attributes after associations are set in stone
      release.filename ||=
        "#{release.name}-#{release.version}.#{release.filetype.key}"
    end

    trait :unpublished do
      after :build do |release, evaluator|
        release.artifact = nil
      end
    end

    trait :published do
      after :build do |release, evaluator|
        release.artifact ||= build(:release_artifact,
          account: release.account,
          product: release.product,
          release: release,
          key: release.filename,
        )
      end
    end
  end
end
