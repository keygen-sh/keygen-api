FactoryGirl.define do
  factory :user do
    first_name { Faker::Name.name }
    last_name { Faker::Name.name }
    email { [SecureRandom.hex, Faker::Internet.safe_email].join }
    password "password"

    association :account

    after :build do |user, evaluator|
      account = evaluator.account or create :account

      user.assign_attributes(
        account: account
      )
    end

    after :create do |user|
      user.role = create :role, :user, resource: user
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
