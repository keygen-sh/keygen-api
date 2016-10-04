FactoryGirl.define do
  factory :webhook_event do
    endpoint { Faker::Internet.url }
    jid { SecureRandom.hex }
  end
end
