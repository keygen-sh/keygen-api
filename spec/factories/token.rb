# frozen_string_literal: true

FactoryGirl.define do
  factory :token do
    account nil
    bearer nil

    after :build do |token, evaluator|
      account = evaluator.account.presence || create(:account)
      bearer =
        if evaluator.bearer.present?
          evaluator.bearer
        else
          create :user, account: account
        end

      token.assign_attributes(
        digest: "test_#{SecureRandom.hex}",
        account: bearer.account,
        bearer: bearer
      )
    end
  end
end
