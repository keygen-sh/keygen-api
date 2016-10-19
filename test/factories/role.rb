FactoryGirl.define do

  factory :user_role, class: Role do |role|
    name :user
  end

  factory :admin_role, class: Role do |role|
    name :admin
  end

  factory :product_role, class: Role do |role|
    name :product
  end
end
