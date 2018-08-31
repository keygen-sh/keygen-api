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

    association :account
    association :product

    after :build do |policy, evaluator|
      account = evaluator.account or create :account

      policy.assign_attributes(
        product: create(:product, account: account),
        account: account
      )
    end

    trait :encrypted do
      encrypted true
    end

    trait :pooled do
      use_pool true
    end
  end
end
