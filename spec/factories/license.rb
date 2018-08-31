FactoryGirl.define do
  factory :license do
    association :account
    association :policy
    association :user

    after :build do |license, evaluator|
      account = evaluator.account or create :account
      policy =
        if evaluator.policy.encrypted?
          create :policy, :encrypted, account: account
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

    trait :encrypted do
      association :policy, :encrypted
    end

    after :create do |license|
      create :token, bearer: license
    end
  end
end
