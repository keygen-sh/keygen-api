# frozen_string_literal: true

FactoryGirl.define do
  factory :second_factor do
    account nil
    user nil

    after :build do |second_factor, evaluator|
      account = evaluator.account.presence || create(:account)
      user =
        if evaluator.user.present?
          evaluator.user
        else
          create :user, account: account
        end

      second_factor.assign_attributes(
        account: user.account,
        user: user
      )
    end
  end
end
