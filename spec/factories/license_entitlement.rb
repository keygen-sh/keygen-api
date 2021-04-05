# frozen_string_literal: true

FactoryGirl.define do
  factory :license_entitlement do
    account nil
    entitlement nil
    license

    after :build do |license_entitlement, evaluator|
      account = evaluator.account.presence || create(:account)
      entitlement =
        if evaluator.entitlement.present?
          evaluator.entitlement
        else
          create :entitlement, account: account
        end

      license_entitlement.assign_attributes(
        account: account,
        entitlement: entitlement
      )
    end
  end
end
