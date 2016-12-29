FactoryGirl.define do
  factory :account do
    name { Faker::Company.name }
    slug { [Faker::Internet.domain_word, SecureRandom.hex].join }
    invite_state { :accepted }

    users []
    billing
    plan

    before :create do |account|
      account.users << build(:admin, account: account)
    end
  end
end
