FactoryGirl.define do
  factory :policy do
    name { Faker::Company.buzzword }
    max_machines { nil }
    duration { 2.weeks }
    strict false
    floating false
    use_pool false
    encrypted false
    protected false
    require_check_in false
    check_in_interval nil
    check_in_interval_count nil
    require_product_scope false
    require_policy_scope false
    require_machine_scope false
    require_fingerprint_scope false
    max_uses nil
    scheme nil

    association :account
    association :product

    after :build do |policy, evaluator|
      account = evaluator.account or create :account

      policy.assign_attributes(
        product: create(:product, account: account),
        account: account
      )
    end

    trait :legacy_encrypt do
      scheme 'LEGACY_ENCRYPT'
      encrypted true
    end

    trait :rsa_2048_pkcs1_encrypt do
      scheme 'RSA_2048_PKCS1_ENCRYPT'
      encrypted false
    end

    trait :rsa_2048_pkcs1_sign do
      scheme 'RSA_2048_PKCS1_SIGN'
      encrypted false
    end

    trait :rsa_2048_pkcs1_pss_sign do
      scheme 'RSA_2048_PKCS1_PSS_SIGN'
      encrypted false
    end

    trait :rsa_2048_jwt_rs256 do
      scheme 'RSA_2048_JWT_RS256'
      encrypted false
    end

    trait :day_check_in do
      require_check_in true
      check_in_interval 'day'
      check_in_interval_count 1
    end

    trait :week_check_in do
      require_check_in true
      check_in_interval 'week'
      check_in_interval_count 1
    end

    trait :month_check_in do
      require_check_in true
      check_in_interval 'month'
      check_in_interval_count 1
    end

    trait :year_check_in do
      require_check_in true
      check_in_interval 'year'
      check_in_interval_count 1
    end

    trait :pooled do
      use_pool true
    end
  end
end
