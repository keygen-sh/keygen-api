# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    account { nil }
    bearer { nil }

    after :build do |token, evaluator|
      account = evaluator.account.presence
      bearer =
        if evaluator.bearer.present?
          evaluator.bearer
        else
          build(:user, account: account)
        end

      token.assign_attributes(
        digest: "test_#{SecureRandom.hex}",
        account: bearer.account,
        bearer: bearer,
      )
    end
  end
end
