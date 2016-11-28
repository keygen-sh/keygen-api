FactoryGirl.define do
  factory :account do
    company { Faker::Company.name }
    name { [Faker::Internet.domain_word, SecureRandom.hex].join }

    users []
    billing
    plan

    before :create do |account|
      account.users << build(:admin, account: account)
    end
  end
end
