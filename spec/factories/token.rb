FactoryGirl.define do
  factory :token do
    account nil
    bearer nil

    before :create do |token|
      if token.bearer.nil?
        token.bearer = create :user
      end
      token.account = token.bearer.account
    end
  end
end
