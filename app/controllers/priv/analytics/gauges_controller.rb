# frozen_string_literal: true

module Priv::Analytics
  class GaugesController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    def show
      authorize! with: Accounts::AnalyticsPolicy

      gauge = Analytics::Gauge.new(
        params[:gauge],
      )

      unless gauge.valid?
        render_bad_request *gauge.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
        )

        return
      end

      data = Rails.cache.fetch gauge.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        gauge.as_json
      end

      render json: { data: }
    rescue Analytics::GaugeNotFoundError
      render_not_found
    end
  end
end
