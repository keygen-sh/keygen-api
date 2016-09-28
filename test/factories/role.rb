FactoryGirl.define do

  factory :create_role, class: Role do |role|
    name :create
  end

  factory :read_role, class: Role do |role|
    name :read
  end

  factory :update_role, class: Role do |role|
    name :update
  end

  factory :delete_role, class: Role do |role|
    name :delete
  end
end
