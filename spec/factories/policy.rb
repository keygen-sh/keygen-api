FactoryGirl.define do
  factory :policy do
    name { Faker::Company.buzzword }
    price { Faker::Number.number 4 }
    max_machines { Faker::Number.between 1, 5000 }
    duration { 2.weeks }
    strict false
    recurring false
    floating false
    use_pool false
    encrypted false
    protected false
    pool []
    account
    product

    trait :encrypted do
      encrypted true
    end

    trait :pooled do
      use_pool true
    end
  end
end
