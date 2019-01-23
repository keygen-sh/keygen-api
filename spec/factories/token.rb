FactoryGirl.define do
  factory :token do
    account nil
    bearer nil

    before :create do |token|
      if token.digest.nil?
        token.digest = "rand_#{SecureRandom.hex}"
      end
      if token.bearer.nil?
        token.bearer = create :user
      end
      token.account = token.bearer.account
    end
  end
end
