FactoryGirl.define do

  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password "password"
    token nil
    account
    before :create do |user|
      user.token = build :user_token, account: user.account, bearer: user
      user.licenses << build(:license, user: user)
    end
  end

  factory :admin, class: User do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    password "password"
    token nil
    account
    before :create do |user|
      user.token = build :admin_token, account: user.account, bearer: user
    end
  end
end
