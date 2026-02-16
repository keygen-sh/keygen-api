# frozen_string_literal: true

module Priv::Analytics
  class StatsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    def show
      authorize! with: Accounts::AnalyticsPolicy

      stat = Analytics::Stat.call(params[:stat_id], account: current_account, environment: current_environment)

      unless stat.valid?
        render_bad_request detail: stat.errors.full_messages.to_sentence,
                           source: { parameter: stat.errors.attribute_names.first }
        return
      end

      data = cached { stat.result.as_json }

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
