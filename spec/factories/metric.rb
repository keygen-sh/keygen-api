FactoryGirl.define do
  factory :metric do
    metric { "test.metric" }
    data { { data: "data" } }
  end
end
