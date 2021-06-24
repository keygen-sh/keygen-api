# frozen_string_literal: true

FactoryGirl.define do
  factory :release do
    name { Faker::App.name }
    filename { "#{name}-#{version}.#{filetype.key}" }
    filesize { Faker::Number.between(from: 0, to: 1.gigabyte.to_i) }

    # Add build tag so that there's no chance for collisions
    version {
      if channel.pre_release?
        "#{Faker::App.semantic_version}-#{channel.key}+build.#{Time.current.to_f}"
      else
        "#{Faker::App.semantic_version}+build.#{Time.current.to_f}"
      end
    }

    account nil
    product nil

    association :platform, factory: :release_platform
    association :filetype, factory: :release_filetype
    association :channel, factory: :release_channel

    after :build do |release, evaluator|
      release.account  ||= evaluator.account.presence || create(:account)
      release.product  ||= evaluator.product.presence || create(:product, account: release.account)
      release.platform ||= evaluator.platform.presence || create(:release_platform, account: release.account)
      release.filetype ||= evaluator.filetype.presence || create(:release_filetype, account: release.account)
      release.channel  ||= evaluator.channel.presence || create(:release_channel, account: release.account)
    end
  end
end
