FactoryGirl.define do
  factory :license do
    machines []
    account
    policy
    user

    trait :encrypted do
      association :policy, :encrypted
    end

    after :create do |license|
      create :token, bearer: license
    end
  end
end
