FactoryGirl.define do
  factory :webhook_event do
    endpoint { Faker::Internet.url }
    payload { { payload: "payload" }.to_json }
    jid { SecureRandom.hex }
  end
end
