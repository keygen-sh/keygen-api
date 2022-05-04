# frozen_string_literal: true

FactoryBot.define do
  factory :release_artifact, aliases: %i[artifact] do
    filename { nil }
    filesize { Faker::Number.between(from: 0, to: 1.gigabyte.to_i) }

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
  end
end
