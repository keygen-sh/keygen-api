# frozen_string_literal: true

FactoryBot.define do
  factory :release_specification, aliases: %i[spec specification] do
    initialize_with { new(**attributes) }

    account       { NIL_ACCOUNT }
    specification { nil }

    trait :gem do
      specification { Gem::Package.new(file_fixture('valid.gem').open).spec.as_json }
    end
  end
end
