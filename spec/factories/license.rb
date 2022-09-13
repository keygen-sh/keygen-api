# frozen_string_literal: true

FactoryBot.define do
  factory :license do
    account { nil }
    policy { nil }
    user { nil }

    after :build do |license, evaluator|
      account = evaluator.account.presence
      policy  = evaluator.policy.presence || build(:policy, account: account)
      user    =
        case
        when evaluator.user.present?
          evaluator.user
        else
          nil
        end

      license.assign_attributes(
        account: account,
        policy: policy,
        user: user,
      )
    end

    trait :legacy_encrypt do
      after :build do |license, evaluator|
        license.policy = build(:policy, :legacy_encrypt, account: license.account)
      end
    end

    trait :rsa_2048_pkcs1_encrypt do
      after :build do |license, evaluator|
        license.policy = build(:policy, :rsa_2048_pkcs1_encrypt, account: license.account)
      end
    end

    trait :rsa_2048_pkcs1_sign do
      after :build do |license, evaluator|
        license.policy = build(:policy, :rsa_2048_pkcs1_sign, account: license.account)
      end
    end

    trait :rsa_2048_pkcs1_pss_sign do
      after :build do |license, evaluator|
        license.policy = build(:policy, :rsa_2048_pkcs1_pss_sign, account: license.account)
      end
    end

    trait :rsa_2048_jwt_rs256 do
      after :build do |license, evaluator|
        license.policy = build(:policy, :rsa_2048_jwt_rs256, account: license.account)
      end
    end

    trait :rsa_2048_pkcs1_sign_v2 do
      after :build do |license, evaluator|
        license.policy = build(:policy, :rsa_2048_pkcs1_sign_v2, account: license.account)
      end
    end

    trait :rsa_2048_pkcs1_pss_sign_v2 do
      after :build do |license, evaluator|
        license.policy = build(:policy, :rsa_2048_pkcs1_pss_sign_v2, account: license.account)
      end
    end

    trait :ed25519_sign do
      after :build do |license, evaluator|
        license.policy = build(:policy, :ed25519_sign, account: license.account)
      end
    end

    trait :day_check_in do
      after :build do |license, evaluator|
        license.policy = build(:policy, :day_check_in, account: license.account)
      end
    end

    trait :week_check_in do
      after :build do |license, evaluator|
        license.policy = build(:policy, :week_check_in, account: license.account)
      end
    end

    trait :month_check_in do
      after :build do |license, evaluator|
        license.policy = build(:policy, :month_check_in, account: license.account)
      end
    end

    trait :year_check_in do
      after :build do |license, evaluator|
        license.policy = build(:policy, :year_check_in, account: license.account)
      end
    end

    trait :restrict_access_expiration_strategy do
      after :build do |license, evaluator|
        license.policy = build(:policy, :restrict_access_expiration_strategy, account: license.account)
      end
    end

    trait :revoke_access_expiration_strategy do
      after :build do |license, evaluator|
        license.policy = build(:policy, :revoke_access_expiration_strategy, account: license.account)
      end
    end

    trait :allow_access_expiration_strategy do
      after :build do |license, evaluator|
        license.policy = build(:policy, :allow_access_expiration_strategy, account: license.account)
      end
    end

    trait :userless do |license|
      # FIXME(ezekg) This kind of acts as a sentinel value to not create a user
      #              in the factory's create hook (above)
      user { false }
    end

    trait :expired do
      after :build do |license|
        license.expiry = 1.month.ago
      end
    end

    trait :protected do |license|
      protected { true }
    end

    trait :unprotected do |license|
      protected { false }
    end

    trait :with_entitlements do
      after :create do |license|
        create_list(:license_entitlement, 6, account: license.account, license:)
      end
    end

    trait :with_user do
      after :create do |license|
        license.update(user: build(:user, account: license.account))
      end
    end
  end
end
