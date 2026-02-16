# frozen_string_literal: true

module Priv::Analytics
  class StatsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    def show
      authorize! with: Accounts::AnalyticsPolicy

      stat = Analytics::Stat.new(params[:stat_id])

      unless stat.valid?
        render_bad_request detail: stat.errors.full_messages.to_sentence,
                           source: { parameter: stat.errors.attribute_names.first }
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
