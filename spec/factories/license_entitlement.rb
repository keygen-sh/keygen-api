# frozen_string_literal: true

FactoryBot.define do
  factory :license_entitlement do
    account { nil }
    entitlement { nil }
    license { nil }

    after :build do |license_entitlement, evaluator|
      license_entitlement.account     ||= evaluator.account.presence
      license_entitlement.entitlement ||=
        evaluator.entitlement.presence || build(:entitlement, account: license_entitlement.account)
    end
  end
end
