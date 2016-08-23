FactoryGirl.define do
  factory :license do
    key { SecureRandom.hex(12).upcase.scan(/.{4}/).join "-" }
    expiry { 2.weeks.from_now }
    machines []
    account
    policy
    user
  end
end
