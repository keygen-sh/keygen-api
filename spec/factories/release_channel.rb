# frozen_string_literal: true

FactoryGirl.define do
  factory :release_channel do
    name { "Stable" }
    key { "stable" }

    account nil

    after :build do |release, evaluator|
      account = evaluator.account.presence || create(:account)

      release.assign_attributes(
        account: account
      )
    end
  end
end
