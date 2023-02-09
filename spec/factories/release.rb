# frozen_string_literal: true

FactoryBot.define do
  factory :release do
    name { Faker::App.name }
    version { nil }
    status { 'PUBLISHED' }

    account { nil }
    product { nil }
    artifacts { [] }
    channel { nil }

    after :build do |release, evaluator|
      release.account  ||= evaluator.account.presence
      release.product  ||= evaluator.product.presence || build(:product, account: release.account)
      release.channel  ||= evaluator.channel.presence || build(:channel, key: 'stable', account: release.account)

      # Add build tag so that there's no chance for collisions
      release.version ||=
        if release.channel.pre_release?
          "#{Faker::App.semantic_version}-#{release.channel.key}+build.#{Time.current.to_f}"
        else
          "#{Faker::App.semantic_version}+build.#{Time.current.to_f}"
        end

      # Make sure channel matches semver prerelease channel
      semver = Semverse::Version.coerce(release.version)

      if semver.pre_release?
        key = semver.pre_release[/([^\.]+)/, 1]

        release.channel.assign_attributes(
          name: key.capitalize,
          key:,
        )
      end
    end

    trait :draft do
      after :build do |release, evaluator|
        release.status = 'DRAFT'
      end
    end

    trait :published do
      after :build do |release, evaluator|
        release.status = 'PUBLISHED'
      end
    end

    trait :yanked do
      after :build do |release, evaluator|
        release.yanked_at = Time.current
        release.status    = 'YANKED'
      end
    end

    trait :licensed do
      after :build do |release, evaluator|
        release.product = build(:product, :licensed, account: release.account)
      end
    end

    trait :open do
      after :build do |release, evaluator|
        release.product = build(:product, :open, account: release.account)
      end
    end

    trait :closed do
      after :build do |release, evaluator|
        release.product = build(:product, :closed, account: release.account)
      end
    end

    trait :created_last_year do
      after :build do |release, evaluator|
        release.created_at = 1.year.ago
      end
    end

    trait :with_constraints do
      after :create do |release|
        create_list(:release_entitlement_constraint, 10, account: release.account, release:)
      end
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
