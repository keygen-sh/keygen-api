FactoryGirl.define do
  factory :account do
    name { Faker::Company.name }
    subdomain { [Faker::Internet.domain_word, Faker::Internet.domain_word].join }
    activated true
    users []
    billing
    plan
    before :create do |account|
      account.users << build(:admin, account: account)
    end
  end
end
