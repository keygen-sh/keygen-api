FactoryGirl.define do
  factory :token do
    account nil
    bearer nil

    before :create do |token|
      token.account = token.bearer.account
    end
  end
end
