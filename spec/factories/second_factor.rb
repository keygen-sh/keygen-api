# frozen_string_literal: true

FactoryGirl.define do
  factory :second_factor do
    account nil
    user nil

    before :create do |token|
      if token.user.nil?
        token.user = create :user
      end
      token.account = token.user.account
    end
  end
end
