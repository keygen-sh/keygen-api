FactoryGirl.define do
  factory :key do
    key { SecureRandom.hex(12).upcase.scan(/.{4}/).join "-" }
    account
    policy
  end
end
