# frozen_string_literal: true

FactoryBot.define do
  factory :release_artifact, aliases: %i[artifact] do
    filename { nil }
    filesize { Faker::Number.between(from: 0, to: 1.gigabyte.to_i) }
    status { 'UPLOADED' }

    account  { nil }
    release  { nil }
    platform { nil }
    arch     { nil }
    filetype { nil }

    after :build do |artifact, evaluator|
      artifact.account  ||= evaluator.account.presence
      artifact.release  ||= evaluator.release.presence || build(:release, account: artifact.account)
      artifact.platform ||= evaluator.platform.presence || build(:platform, key: 'darwin', account: artifact.account)
      artifact.arch     ||= evaluator.arch.presence || build(:arch, key: 'amd64', account: artifact.account)
      artifact.filetype ||= evaluator.filetype.presence || build(:filetype, key: 'dmg', account: artifact.account)

      # Add dependant attributes after associations are set in stone
      artifact.filename ||=
        "#{artifact.release.name}-#{artifact.release.version}+#{SecureRandom.hex}.#{artifact.filetype.key}"
    end

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
      after :build do |artifact, evaluator|
        artifact.status = 'WAITING'
      end
    end

    trait :uploaded do
      after :build do |artifact, evaluator|
        artifact.status = 'UPLOADED'
      end
    end

    trait :failed do
      after :build do |artifact, evaluator|
        artifact.status = 'FAILED'
      end
    end

    trait :yanked do
      after :build do |artifact, evaluator|
        artifact.status = 'YANKED'
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
