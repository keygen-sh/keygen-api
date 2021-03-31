# frozen_string_literal: true

FactoryGirl.define do
  factory :key do
    key { SecureRandom.hex(12).upcase.scan(/.{4}/).join "-" }

    account nil
    policy nil

    after :build do |key, evaluator|
      account = evaluator.account.presence || create(:account)
      policy = create :policy, :pooled, account: account

      key.assign_attributes(
        account: account,
        policy: policy
      )
    end
  end
end
