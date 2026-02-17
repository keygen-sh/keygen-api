# frozen_string_literal: true

module Priv::Analytics
  class LeaderboardsController < BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :limit, type: :integer, coerce: true, optional: true
      param :date, type: :hash, optional: true do
        param :start, type: :date, coerce: true
        param :end, type: :date, coerce: true
      end
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      options = leaderboard_query.reduce({}) do |hash, (key, value)|
        hash.merge(
          case { key => value }
          in date: { start: start_date, end: end_date }
            { start_date:, end_date: } # flatten date
          else
            { key => value }
          end
        )
      end

      leaderboard = Analytics::Leaderboard.new(
        params[:leaderboard_id],
        **options,
      )

      unless leaderboard.valid?
        render_bad_request *leaderboard.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            # remap our attributes to params source
            parameters: {
              start_date: 'date[start]',
              end_date: 'date[end]',
            },
          },
        )

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
