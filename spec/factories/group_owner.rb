# frozen_string_literal: true

FactoryBot.define do
  factory :group_owner do
    account { nil }
    group { nil }
    user { nil }

    after :build do |group_owner, evaluator|
      group_owner.account ||= evaluator.account.presence
      group_owner.group   ||=
        evaluator.group.presence || build(:group, account: group_owner.account)
      group_owner.user    ||=
        evaluator.user.presence || build(:user, account: group_owner.account)
    end
  end
end
