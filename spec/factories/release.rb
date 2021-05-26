# frozen_string_literal: true

FactoryGirl.define do
  factory :release do
    name { Faker::App.name }
    key { "#{name}-#{version}.dmg" }
    version { Faker::App.semantic_version }
    filesize { Faker::Number.between(from: 1.megabyte.to_i, to: 1.gigabyte.to_i) }

    account nil
    product nil
    platform nil
    filetype nil
    channel nil

    after :build do |release, evaluator|
      account = evaluator.account.presence || create(:account)
      platform = evaluator.platform.presence || create(:release_platform, account: account)
      filetype = evaluator.filetype.presence || create(:release_filetype, account: account)
      channel = evaluator.channel.presence || create(:release_channel, account: account)
      product =
        case
        when evaluator.product.present?
          evaluator.product
        else
          create :product, account: account
        end

      release.assign_attributes(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        channel: channel,
      )
    end
  end
end
