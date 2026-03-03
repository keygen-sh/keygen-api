# frozen_string_literal: true

FactoryBot.define do
  factory :release_download_spark do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    product_id   { SecureRandom.uuid }
    package_id   { SecureRandom.uuid }
    release_id   { SecureRandom.uuid }
    count        { 0 }
    created_date { Date.yesterday }
    created_at   { Time.current }
  end
end
