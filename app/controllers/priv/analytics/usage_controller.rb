# frozen_string_literal: true

module Priv::Analytics
  class UsageController < BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :date, type: :hash, optional: true, collapse: { format: :child_parent } do
        param :start, type: :date, coerce: true
        param :end, type: :date, coerce: true
      end
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      usage = Analytics::Usage.new(
        **usage_query,
      )

      unless usage.valid?
        render_bad_request *usage.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              start_date: 'date[start]',
              end_date: 'date[end]',
            },
          },
        )

        return
      end

      data = Rails.cache.fetch usage.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        usage.as_json
      end

      render json: { data: }
    end
  end
end
