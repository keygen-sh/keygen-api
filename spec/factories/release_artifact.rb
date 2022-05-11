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
      artifact.platform ||= evaluator.platform.presence || build(:platform, account: artifact.account)
      artifact.arch     ||= evaluator.arch.presence || build(:arch, account: artifact.account)
      artifact.filetype ||= evaluator.filetype.presence || build(:filetype, account: artifact.account)

      # Add dependant attributes after associations are set in stone
      artifact.filename ||=
        "#{artifact.release.name}-#{artifact.release.version}+#{SecureRandom.hex}.#{artifact.filetype.key}"
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
  end
end
