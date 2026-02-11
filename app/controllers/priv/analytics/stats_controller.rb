# frozen_string_literal: true

module Priv::Analytics
  class StatsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    def show
      authorize! with: Accounts::AnalyticsPolicy

      data = cached do
        Analytics::Stat.call(params[:stat_id], account: current_account, environment: current_environment)
                       .as_json
      end

      render json: { data: }
    rescue Analytics::StatNotFoundError
      render_not_found
    end

    private

    def cached(&) = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL, &)
    def cache_key
      [:analytics, :stats, params[:stat_id], current_account.id, current_environment&.id, CACHE_KEY_VERSION].compact.join(':')
    end
  end
end
