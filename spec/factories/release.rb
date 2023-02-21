# frozen_string_literal: true

FactoryBot.define do
  factory :release do
    name    { Faker::App.name }
    version { nil }
    status  { 'PUBLISHED' }

    account     { nil }
    environment { nil }
    product     { build(:product, account:, environment:) }
    channel     { build(:channel, key: 'stable', account:) }
    artifacts   { [] }

    after :build do |release, evaluator|
      # Add build tag so that there's no chance for collisions
      release.version ||=
        if release.channel.pre_release?
          "#{Faker::App.semantic_version}-#{release.channel.key}+build.#{Time.current.to_f}"
        else
          "#{Faker::App.semantic_version}+build.#{Time.current.to_f}"
        end

      # Make sure channel matches semver prerelease channel
      if (semver = Semverse::Version.coerce(release.version)).pre_release?
        key = semver.pre_release[/([^\.]+)/, 1]

        release.channel.assign_attributes(
          name: key.capitalize,
          key:,
        )
      end
    end

    trait :draft do
      status { 'DRAFT' }
    end

    trait :published do
      status { 'PUBLISHED' }
    end

    trait :yanked do
      yanked_at { Time.current }
      status    { 'YANKED' }
    end

    trait :licensed do
      product { association(:product, :licensed, account:) }
    end

    trait :open do
      product { association(:product, :open, account:) }
    end

    trait :closed do
      product { association(:product, :closed, account:) }
    end

    trait :created_last_year do
      created_at { 1.year.ago }
    end

    trait :with_constraints do
      after :create do |release|
        create_list(:release_entitlement_constraint, 10, account: release.account, release:)
      end
    end

    trait :in_isolated_environment do
      environment { association(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { association(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      after :create do |release|
        release.environment = nil
        release.save!(validate: false)
      end
    end

    trait :global do
      in_nil_environment
    end
  end
end
