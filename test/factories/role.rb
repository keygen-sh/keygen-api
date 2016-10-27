FactoryGirl.define do
  factory :role do
    association :resource, factory: :user

    trait :user do
      name :user
    end

    trait :admin do
      name :admin
    end

    trait :product do
      association :resource, factory: :product
      name :product
    end
  end
end
