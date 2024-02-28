# frozen_string_literal: true

FactoryBot.define do
  factory :license_user do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    license     { build(:license, account:, environment:) }
    user        { build(:user, account:, environment:) }
  end
end
