FactoryGirl.define do
  factory :license do
    association :account
    association :policy
    association :user

    after :build do |license, evaluator|
      account = evaluator.account or create :account
      policy =
        if evaluator.policy.encrypted?
          scheme = evaluator.policy.encryption_scheme.downcase.to_sym

          create :policy, scheme, account: account
        else
          create :policy, account: account
        end
      user = create :user, account: account

      license.assign_attributes(
        account: account,
        policy: policy,
        user: user
      )
    end

    trait :legacy_encrypt do
      association :policy, :legacy_encrypt
    end

    trait :rsa_2048_pkcs1_encrypt do
      association :policy, :rsa_2048_pkcs1_encrypt
    end

    trait :rsa_2048_pkcs1_sign do
      association :policy, :rsa_2048_pkcs1_sign
    end

    trait :rsa_2048_pkcs1_pss_sign do
      association :policy, :rsa_2048_pkcs1_pss_sign
    end

    trait :rsa_2048_jwt_rs256 do
      association :policy, :rsa_2048_jwt_rs256
    end

    after :create do |license|
      create :token, bearer: license
    end
  end
end
