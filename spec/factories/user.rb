FactoryGirl.define do
  factory :user do
    first_name { Faker::Name.name }
    last_name { Faker::Name.name }
    email { [SecureRandom.hex, Faker::Internet.safe_email].join }
    password "password"

    account

    after :create do |user|
      user.role = create :role, :user, resource: user
      create_list :license, 1, user: user
      create :token, bearer: user
    end

    factory :admin do
      after :create do |admin|
        admin.role = create :role, :admin, resource: admin
        create :token, bearer: admin
      end
    end
  end
end
