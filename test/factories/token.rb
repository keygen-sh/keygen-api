FactoryGirl.define do

  factory :user_token, class: Token do
    roles { |token|
      [
        build(:create_role, resource: token.bearer),
        build(:read_role,   resource: token.bearer),
        build(:update_role, resource: token.bearer),
        build(:delete_role, resource: token.bearer),
      ]
    }
  end

  factory :admin_token, class: Token do
    roles { |token|
      [
        build(:create_role, resource: token.account),
        build(:read_role,   resource: token.account),
        build(:update_role, resource: token.account),
        build(:delete_role, resource: token.account),
      ]
    }
  end

  factory :product_token, class: Token do
    roles { |token|
      [
        build(:create_role, resource: token.bearer),
        build(:read_role,   resource: token.bearer),
        build(:update_role, resource: token.bearer),
        build(:delete_role, resource: token.bearer),
      ]
    }
  end
end
