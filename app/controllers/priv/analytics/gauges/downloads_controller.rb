# frozen_string_literal: true

module Priv::Analytics::Gauges
  class DownloadsController < Priv::Analytics::BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :product, type: :uuid, optional: true, as: :product_id
      param :package, type: :uuid, optional: true, as: :package_id
      param :release, type: :uuid, optional: true, as: :release_id
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      gauge = Analytics::Gauge.new(
        :downloads,
        **download_query,
      )

      unless gauge.valid?
        render_bad_request *gauge.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              product_id: 'product',
              package_id: 'package',
              release_id: 'release',
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
