# frozen_string_literal: true

FactoryBot.define do
  factory :release_upload_link do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    release     { build(:release, account:, environment:) }

    url { Faker::Internet.url }
  end
end
