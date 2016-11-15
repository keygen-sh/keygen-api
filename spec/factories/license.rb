FactoryGirl.define do
  factory :license do
    machines []
    account
    policy
    user

    trait :encrypted do
      association :policy, :encrypted
    end
  end
end
