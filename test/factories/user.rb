FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password "password"

    account

    after :create do |user|
      create_list :license, 1, user: user
      create :role, :user, resource: user
      create :token, bearer: user
    end

    factory :admin do
      after :create do |admin|
        create :role, :admin, resource: admin
        create :token, bearer: admin
      end
    end
  end
end
