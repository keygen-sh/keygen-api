FactoryGirl.define do

  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password { Faker::Internet.password }
    role "user"
    account
  end

  factory :admin, class: User do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password { Faker::Internet.password }
    role "admin"
    account
  end
end
