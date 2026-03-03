# frozen_string_literal: true

module Priv::Analytics::Sparks
  class DownloadsController < Priv::Analytics::BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :product, type: :uuid, optional: true, as: :product_id
      param :package, type: :uuid, optional: true, as: :package_id
      param :release, type: :uuid, optional: true, as: :release_id
      param :date, type: :hash, optional: true, collapse: { format: :child_parent } do
        param :start, type: :date, coerce: true
        param :end, type: :date, coerce: true
      end
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      series = Analytics::Series.new(
        :downloads,
        **download_query,
      )

      unless series.valid?
        render_bad_request *series.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              product_id: 'product',
              package_id: 'package',
              release_id: 'release',
              start_date: 'date[start]',
              end_date: 'date[end]',
            },
          },
        )

        return
      end

      data = Rails.cache.fetch series.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        series.as_json
      end

      render json: { data: }
    end
  end
end
