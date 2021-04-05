# frozen_string_literal: true

FactoryGirl.define do
  factory :policy_entitlement do
    account nil
    entitlement nil
    policy

    after :build do |policy_entitlement, evaluator|
      account = evaluator.account.presence || create(:account)
      entitlement =
        if evaluator.entitlement.present?
          evaluator.entitlement
        else
          create :entitlement, account: account
        end

      policy_entitlement.assign_attributes(
        account: account,
        entitlement: entitlement
      )
    end
  end
end
