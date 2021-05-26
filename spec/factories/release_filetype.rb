# frozen_string_literal: true

FactoryGirl.define do
  factory :release_filetype do
    name { "DMG" }
    key { "dmg" }

    account nil

    after :build do |release, evaluator|
      account = evaluator.account.presence || create(:account)

      release.assign_attributes(
        account: account
      )
    end
  end
end
