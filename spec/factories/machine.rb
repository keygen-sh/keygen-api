FactoryGirl.define do
  factory :machine do
    fingerprint { SecureRandom.hex(12).upcase.scan(/.{2}/).join ":" }
    name { Faker::Company.buzzword }
    account
    license
    user
  end
end
