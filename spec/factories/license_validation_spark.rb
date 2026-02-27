# frozen_string_literal: true

FactoryBot.define do
  factory :license_validation_spark do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    license_id      { SecureRandom.uuid }
    validation_code { 'VALID' }
    count           { 0 }
    created_date    { Date.yesterday }
    created_at      { Time.current }
  end
end
