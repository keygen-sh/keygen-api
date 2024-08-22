# frozen_string_literal: true

FactoryBot.define do
  factory :release_upgrade_link do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    release     { build(:release, account:, environment:) }

    url { Faker::Internet.url }
  end
end
