FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password "password"

    account

    after :create do |user|
      create_list :license, 1, user: user
      create :token, bearer: user

      user.save
    end

    factory :admin do
      after :create do |admin|
        create :token, bearer: admin

        user.save
      end
    end
  end
end
