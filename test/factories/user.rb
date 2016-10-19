FactoryGirl.define do

  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password "password"
    account
    before :create do |user|
      user.licenses << build(:license, user: user)
    end
  end

  factory :admin, class: User do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password "password"
    account
    after :create do |user|
      user.roles = [build(:admin_role, resource: user)]
    end
  end
end
