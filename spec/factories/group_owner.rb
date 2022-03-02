# frozen_string_literal: true

FactoryGirl.define do
  factory :group_owner do
    group nil
    user nil

    after :build do |group_owner, evaluator|
      group_owner.account ||= evaluator.account.presence || create(:account)
      group_owner.group   ||=
        evaluator.group.presence || create(:group, account: group_owner.account)
      group_owner.user    ||=
        evaluator.user.presence || create(:user, account: group_owner.account)
    end
  end
end
