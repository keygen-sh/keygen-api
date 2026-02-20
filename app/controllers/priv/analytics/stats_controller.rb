# frozen_string_literal: true

module Priv::Analytics
  class StatsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    def show
      authorize! with: Accounts::AnalyticsPolicy

      stat = Analytics::Stat.new(
        params[:stat],
      )

      unless stat.valid?
        render_bad_request *stat.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
        )

        return
      end

      data = Rails.cache.fetch stat.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        stat.as_json
      end

      render json: { data: }
    rescue Analytics::StatNotFoundError
      render_not_found
    end
  end
end
