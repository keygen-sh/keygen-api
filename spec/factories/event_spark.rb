# frozen_string_literal: true

FactoryBot.define do
  factory :event_spark do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    event_type_id { create(:event_type, event: 'license.created').id }
    count         { 0 }
    created_date  { Date.yesterday }
    created_at    { Time.current }
  end
end
