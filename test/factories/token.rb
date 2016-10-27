FactoryGirl.define do
  factory :token do
    association :bearer, factory: :user
    account nil

    before :create do |token|
      token.account = token.bearer.account
    end

    factory :product_token do
      association :bearer, factory: :product
    end
  end
end
