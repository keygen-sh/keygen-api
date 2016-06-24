FactoryGirl.define do
  factory :account do
    name { Faker::Company.name }
    subdomain { Faker::Internet.domain_word }
    activated true
    users { |a| [association(:admin, account_id: a.id)] }
    billing
    plan
  end
end
