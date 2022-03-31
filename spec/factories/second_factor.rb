# frozen_string_literal: true

FactoryBot.define do
  factory :second_factor do
    account { nil }
    user { nil }

    after :build do |second_factor, evaluator|
      account = evaluator.account.presence
      user =
        if evaluator.user.present?
          evaluator.user
        else
          build(:user, account: account)
        end

      second_factor.assign_attributes(
        account: user.account,
        user: user
      )
    end
  end
end
