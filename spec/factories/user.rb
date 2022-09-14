# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.name }
    last_name { Faker::Name.name }
    email { [SecureRandom.hex(4), Faker::Internet.safe_email].join('') }
    password { "password" }

    account { nil }

    after :build do |user, evaluator|
      user.account ||= evaluator.account.presence
    end

    factory :admin do
      role { build(:role, :admin) }
    end

    factory :developer do
      role { build(:role, :developer) }
    end

    factory :support_agent do
      role { build(:role, :support_agent) }
    end

    factory :sales_agent do
      role { build(:role, :sales_agent) }
    end

    factory :read_only do
      role { build(:role, :read_only) }
    end

    trait :passwordless do
      password { nil }
    end

    trait :with_licenses do
      after :create do |user|
        create_list(:license, 3, account: user.account, user:)
      end
    end

    trait :with_entitlements do
      after :create do |user|
        licenses = user.licenses.presence || create_list(:license, 3, account: user.account, user:)

        licenses.each do |license|
          create_list(:license_entitlement, 2, account: license.account, license:)
        end

        user.licenses.reload
      end
    end
  end
end
