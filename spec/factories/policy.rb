# frozen_string_literal: true

FactoryBot.define do
  factory :policy do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    name                      { Faker::Company.buzzword }
    max_machines              { nil }
    duration                  { 2.weeks }
    strict                    { false }
    floating                  { true }
    use_pool                  { false }
    encrypted                 { false }
    protected                 { false }
    require_check_in          { false }
    check_in_interval         { nil }
    check_in_interval_count   { nil }
    require_product_scope     { false }
    require_policy_scope      { false }
    require_machine_scope     { false }
    require_fingerprint_scope { false }
    max_uses                  { nil }
    scheme                    { nil }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    product     { build(:product, account:, environment:) }

    trait :legacy_encrypt do
      scheme    { 'LEGACY_ENCRYPT' }
      encrypted { true }
    end

    trait :rsa_2048_pkcs1_encrypt do
      scheme    { 'RSA_2048_PKCS1_ENCRYPT' }
      encrypted { false }
    end

    trait :rsa_2048_pkcs1_sign do
      scheme    { 'RSA_2048_PKCS1_SIGN' }
      encrypted { false }
    end

    trait :rsa_2048_pkcs1_pss_sign do
      scheme    { 'RSA_2048_PKCS1_PSS_SIGN' }
      encrypted { false }
    end

    trait :rsa_2048_jwt_rs256 do
      scheme    { 'RSA_2048_JWT_RS256' }
      encrypted { false }
    end

    trait :rsa_2048_pkcs1_sign_v2 do
      scheme    { 'RSA_2048_PKCS1_SIGN_V2' }
      encrypted { false }
    end

    trait :rsa_2048_pkcs1_pss_sign_v2 do
      scheme    { 'RSA_2048_PKCS1_PSS_SIGN_V2' }
      encrypted { false }
    end

    trait :ed25519_sign do
      scheme    { 'ED25519_SIGN' }
      encrypted { false }
    end

    trait :day_check_in do
      require_check_in        { true }
      check_in_interval       { 'day' }
      check_in_interval_count { 1 }
    end

    trait :week_check_in do
      require_check_in        { true }
      check_in_interval       { 'week' }
      check_in_interval_count { 1 }
    end

    trait :month_check_in do
      require_check_in { true }
      check_in_interval { 'month' }
      check_in_interval_count { 1 }
    end

    trait :year_check_in do
      require_check_in        { true }
      check_in_interval       { 'year' }
      check_in_interval_count { 1 }
    end

    trait :pooled do
      use_pool { true }
    end

    trait :floating do
      max_machines { nil }
      floating     { true }
    end

    trait :node_locked do
      max_machines { 1 }
      floating     { false }
    end

    trait :unprotected do
      protected { false }
    end

    trait :protected do
      protected { true }
    end

    trait :restrict_access_expiration_strategy do
      expiration_strategy { 'RESTRICT_ACCESS' }
    end

    trait :revoke_access_expiration_strategy do
      expiration_strategy { 'REVOKE_ACCESS' }
    end

    trait :maintain_access_expiration_strategy do
      expiration_strategy { 'MAINTAIN_ACCESS' }
    end

    trait :allow_access_expiration_strategy do
      expiration_strategy { 'ALLOW_ACCESS' }
    end

    trait :with_entitlements do
      after :create do |policy|
        create_list(:policy_entitlement, 10, account: policy.account, policy:)
      end
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
