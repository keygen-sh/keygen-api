# frozen_string_literal: true

module Priv::Analytics
  class UsageController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    before_action :require_clickhouse!

    typed_query {
      param :start_date, type: :date, coerce: true, optional: true
      param :end_date, type: :date, coerce: true, optional: true
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      usage = Analytics::Usage.new(**usage_query)

      unless usage.valid?
        render_bad_request detail: usage.errors.full_messages.to_sentence,
                           source: { parameter: usage.errors.attribute_names.first }
        return
      end

      data = Rails.cache.fetch usage.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        usage.as_json
      end

      render json: { data: }
    end
  end
end
