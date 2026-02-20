# frozen_string_literal: true

module Priv::Analytics
  class CountsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    def show
      authorize! with: Accounts::AnalyticsPolicy

      count = Analytics::Count.new(
        params[:count],
      )

      unless count.valid?
        render_bad_request *count.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
        )

        return
      end

      data = Rails.cache.fetch count.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        count.as_json
      end

      render json: { data: }
    rescue Analytics::CountNotFoundError
      render_not_found
    end
  end
end
