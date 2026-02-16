# frozen_string_literal: true

module Priv::Analytics
  class LeaderboardsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    before_action :require_clickhouse!

    typed_query {
      param :start_date, type: :date, coerce: true, optional: true
      param :end_date, type: :date, coerce: true, optional: true
      param :limit, type: :integer, coerce: true, optional: true
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      leaderboard = Analytics::Leaderboard.new(
        params[:leaderboard_id],
        **leaderboard_query,
      )

      unless leaderboard.valid?
        render_bad_request detail: leaderboard.errors.full_messages.to_sentence,
                           source: { parameter: leaderboard.errors.attribute_names.first }
        return
      end

      data = Rails.cache.fetch leaderboard.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        leaderboard.as_json
      end

      render json: { data: }
    rescue Analytics::LeaderboardNotFoundError
      render_not_found
    end
  end
end
