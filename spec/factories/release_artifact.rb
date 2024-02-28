# frozen_string_literal: true

FactoryBot.define do
  factory :release_artifact, aliases: %i[artifact] do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    filename { "#{release.name}-#{release.version}+#{SecureRandom.hex}.#{filetype.key}" }
    filesize { Faker::Number.between(from: 0, to: 1.gigabyte.to_i) }
    status   { 'UPLOADED' }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    release     { build(:release, account:, environment:) }
    platform    { build(:platform, key: 'darwin', account:) }
    arch        { build(:arch, key: 'amd64', account:) }
    filetype    { build(:filetype, key: 'dmg', account:) }

    trait :darwin do
      platform { build(:platform, key: 'darwin', account:) }
    end

    trait :linux do
      platform { build(:platform, key: 'linux', account:) }
    end

    trait :win32 do
      platform { build(:platform, key: 'win32', account:) }
    end

    trait :arm64 do
      arch { build(:arch, key: 'arm64', account:) }
    end

    trait :amd64 do
      arch { build(:arch, key: 'amd64', account:) }
    end

    trait :x86 do
      arch { build(:arch, key: 'x86', account:) }
    end

    trait :waiting do
      status { 'WAITING' }
    end

    trait :uploaded do
      status { 'UPLOADED' }
    end

    trait :failed do
      status { 'FAILED' }
    end

    trait :yanked do
      status { 'YANKED' }
    end

    trait :licensed do
      release { build(:release, :licensed, account:, environment:) }
    end

    trait :open do
      release { build(:release, :open, account:, environment:) }
    end

    trait :closed do
      release { build(:release, :closed, account:, environment:) }
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
