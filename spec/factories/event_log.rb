# frozen_string_literal: true

FactoryBot.define do
  factory :event_log do
    account { nil }
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
  end
end
