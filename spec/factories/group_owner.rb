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

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      environment { nil }
    end

    trait :global do
      in_nil_environment
    end
  end
end
