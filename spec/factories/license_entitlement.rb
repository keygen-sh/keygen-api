# frozen_string_literal: true

FactoryGirl.define do
  factory :license_entitlement do
    account nil
    entitlement nil
    license

    after :build do |license_entitlement, evaluator|
      license_entitlement.account     ||= evaluator.account.presence || create(:account)
      license_entitlement.entitlement ||=
        evaluator.entitlement.presence || create(:entitlement, account: license_entitlement.account)
    end
  end
end
