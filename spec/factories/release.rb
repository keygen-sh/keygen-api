# frozen_string_literal: true

FactoryBot.define do
  factory :release do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    name    { Faker::App.name }
    version { nil }
    status  { 'PUBLISHED' }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    product     { build(:product, account:, environment:) }
    channel     { build(:channel, key: 'stable', account:) }
    package     { nil }
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

    trait :packaged do
      package { build(:package, account:, product:, environment:) }
    end

    trait :pypi do
      package { build(:package, :pypi, account:, product:, environment:) }
    end

    trait :licensed do
      product { build(:product, :licensed, account:, environment:) }
    end

    trait :open do
      product { build(:product, :open, account:, environment:) }
    end

    trait :closed do
      product { build(:product, :closed, account:, environment:) }
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
