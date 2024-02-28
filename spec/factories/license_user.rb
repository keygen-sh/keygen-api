# frozen_string_literal: true

FactoryBot.define do
  factory :license_user do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    account     { Current.account }
    environment { Current.environment || NIL_ENVIRONMENT }
    license     { build(:license, account:, environment:) }
    user        { build(:user, account:, environment:) }
  end
end
