FactoryGirl.define do
  factory :plan do
    name { Faker::Company.buzzword }
    price { Faker::Number.number(4) }
    max_users { Faker::Number.between(50, 5000) }
    max_policies { Faker::Number.between(50, 5000) }
    max_licenses { Faker::Number.between(50, 5000) }
    max_products { Faker::Number.between(50, 5000) }
  end
end
