# frozen_string_literal: true

FactoryBot.define do
  factory :user_spark do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    count        { 0 }
    created_date { Date.yesterday }
    created_at   { Time.current }
  end
end
