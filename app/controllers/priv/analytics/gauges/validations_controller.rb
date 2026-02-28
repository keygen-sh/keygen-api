# frozen_string_literal: true

module Priv::Analytics::Gauges
  class ValidationsController < Priv::Analytics::BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :license, type: :uuid, optional: true, as: :license_id
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      gauge = Analytics::Gauge.new(
        :validations,
        **validation_query,
      )

      unless gauge.valid?
        render_bad_request *gauge.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              license_id: 'license',
            },
          },
        )

        return
      end

      data = Rails.cache.fetch gauge.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        gauge.as_json
      end

      render json: { data: }
    end
  end
end
