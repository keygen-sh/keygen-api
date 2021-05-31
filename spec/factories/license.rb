# frozen_string_literal: true

FactoryGirl.define do
  factory :license do
    account nil
    policy nil
    user nil

    after :build do |license, evaluator|
      account = evaluator.account.presence || create(:account)
      policy =
        if evaluator.policy.present?
          case
          when evaluator.policy.scheme?
            scheme = evaluator.policy.scheme.downcase.to_sym

            create :policy, scheme, account: account
          when evaluator.policy.require_check_in?
            interval = "#{evaluator.policy.check_in_interval}_check_in".to_sym

            create :policy, interval, account: account
          else
            evaluator.policy
          end
        else
          create :policy, account: account
        end
      user =
        case
        when evaluator.user == false
          nil
        when evaluator.user.present?
          evaluator.user
        else
          create :user, account: account
        end

      license.assign_attributes(
        account: account,
        policy: policy,
        user: user
      )
    end

    after :create do |license|
      license.role = create :role, :license, resource: license
      create :token, bearer: license
    end

    trait :legacy_encrypt do
      association :policy, :legacy_encrypt, strategy: :build
    end

    trait :rsa_2048_pkcs1_encrypt do
      association :policy, :rsa_2048_pkcs1_encrypt, strategy: :build
    end

    trait :rsa_2048_pkcs1_sign do
      association :policy, :rsa_2048_pkcs1_sign, strategy: :build
    end

    trait :rsa_2048_pkcs1_pss_sign do
      association :policy, :rsa_2048_pkcs1_pss_sign, strategy: :build
    end

    trait :rsa_2048_jwt_rs256 do
      association :policy, :rsa_2048_jwt_rs256, strategy: :build
    end

    trait :rsa_2048_pkcs1_sign_v2 do
      association :policy, :rsa_2048_pkcs1_sign_v2, strategy: :build
    end

    trait :rsa_2048_pkcs1_pss_sign_v2 do
      association :policy, :rsa_2048_pkcs1_pss_sign_v2, strategy: :build
    end

    trait :ed25519_sign do
      association :policy, :ed25519_sign, strategy: :build
    end

    trait :day_check_in do
      association :policy, :day_check_in, strategy: :build
    end

    trait :week_check_in do
      association :policy, :week_check_in, strategy: :build
    end

    trait :month_check_in do
      association :policy, :month_check_in, strategy: :build
    end

    trait :year_check_in do
      association :policy, :year_check_in, strategy: :build
    end

    trait :userless do |license|
      # FIXME(ezekg) This kind of acts as a sentinel value to not create a user
      #              in the factory's create hook (above)
      user false
    end
  end
end
