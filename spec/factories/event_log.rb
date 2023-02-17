# frozen_string_literal: true

FactoryBot.define do
  factory :event_log do
    account     { nil }
    environment { nil }
    event_type

    after :build do |event_log, evaluator|
      account   = evaluator.account.presence
      resource  = evaluator.resource.presence || build(:license, account:)
      whodunnit =
        case
        when evaluator.whodunnit == false
          nil
        when evaluator.whodunnit.present?
          evaluator.whodunnit
        else
          build(:user, account:)
        end

      event_log.assign_attributes(
        account:,
        whodunnit:,
        resource:,
      )
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
