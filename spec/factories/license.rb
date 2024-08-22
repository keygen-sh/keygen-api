# frozen_string_literal: true

FactoryBot.define do
  factory :license do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    policy      { build(:policy, account:, environment:) }
    owner       { nil }

    trait :legacy_encrypt do
      policy { build(:policy, :legacy_encrypt, account:, environment:) }
    end

    trait :rsa_2048_pkcs1_encrypt do
      policy { build(:policy, :rsa_2048_pkcs1_encrypt, account:, environment:) }
    end

    trait :rsa_2048_pkcs1_sign do
      policy { build(:policy, :rsa_2048_pkcs1_sign, account:, environment:) }
    end

    trait :rsa_2048_pkcs1_pss_sign do
      policy { build(:policy, :rsa_2048_pkcs1_pss_sign, account:, environment:) }
    end

    trait :rsa_2048_jwt_rs256 do
      policy { build(:policy, :rsa_2048_jwt_rs256, account:, environment:) }
    end

    trait :rsa_2048_pkcs1_sign_v2 do
      policy { build(:policy, :rsa_2048_pkcs1_sign_v2, account:, environment:) }
    end

    trait :rsa_2048_pkcs1_pss_sign_v2 do
      policy { build(:policy, :rsa_2048_pkcs1_pss_sign_v2, account:, environment:) }
    end

    trait :ed25519_sign do
      policy { build(:policy, :ed25519_sign, account:, environment:) }
    end

    trait :day_check_in do
      policy { build(:policy, :day_check_in, account:, environment:) }
    end

    trait :week_check_in do
      policy { build(:policy, :week_check_in, account:, environment:) }
    end

    trait :month_check_in do
      policy { build(:policy, :month_check_in, account:, environment:) }
    end

    trait :year_check_in do
      policy { build(:policy, :year_check_in, account:, environment:) }
    end

    trait :restrict_access_expiration_strategy do
      policy { build(:policy, :restrict_access_expiration_strategy, account:, environment:) }
    end

    trait :revoke_access_expiration_strategy do
      policy { build(:policy, :revoke_access_expiration_strategy, account:, environment:) }
    end

    trait :maintain_access_expiration_strategy do
      policy { build(:policy, :maintain_access_expiration_strategy, account:, environment:) }
    end

    trait :allow_access_expiration_strategy do
      policy { build(:policy, :allow_access_expiration_strategy, account:, environment:) }
    end

    trait :expired do
      expiry { 1.month.ago }
    end

    trait :suspended do
      suspended { true }
    end

    trait :banned do
      owner { build(:user, :banned, account:, environment:) }
    end

    trait :protected do |license|
      protected { true }
    end

    trait :unprotected do |license|
      protected { false }
    end

    trait :with_entitlements do
      after :create do |license|
        create_list(:license_entitlement, 10, account: license.account, environment: license.environment, license:)
      end
    end

    trait :with_owner do
      owner { build(:user, account:, environment:) }
    end

    trait :without_owner do
      owner { nil }
    end

    trait :owned do
      with_owner
    end

    trait :unowned do
      without_owner
    end

    trait :with_licensees do
      after :create do |license|
        create_list(:license_user, 3, account: license.account, environment: license.environment, license:)
      end
    end

    trait :with_users do
      with_licensees
      with_owner
    end

    trait :without_users do
      # noop
    end

    trait :assigned do
      with_users
    end

    trait :unassigned do
      without_users
    end

    trait :userless do
      unowned
      unassigned
    end

    trait :with_group do
      group { build(:group, account:, environment:) }
    end

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      environment { nil }
    end

    trait :global do
      in_nil_environment
    end
  end
end
