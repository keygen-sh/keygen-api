# frozen_string_literal: true

module Api::V1::RequestLogs::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    # GET /request-logs/actions/count
    def count
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        conn = ActiveRecord::Base.connection

        dates = 13.days.ago.to_date..Date.today
        sql = <<~SQL
          SELECT
            "request_logs"."created_at"::date AS date,
            COUNT(*) AS count
          FROM
            "request_logs"
          WHERE
            "request_logs"."account_id" = #{conn.quote current_account.id} AND
            (
              "request_logs"."created_at" >= #{conn.quote dates.first.beginning_of_day} AND
              "request_logs"."created_at" <= #{conn.quote dates.last.end_of_day}
            )
          GROUP BY
            "request_logs"."created_at"::date
        SQL

        rows = conn.execute sql.squish

        # Create zeroed out hash of dates then merge real counts (so we include dates with no data)
        {
          meta: dates.map { |d| [d.strftime('%Y-%m-%d'), 0] }.to_h
            .merge(
              rows.map { |r| r.fetch_values('date', 'count') }.to_h
            )
        }
      end

      render json: json
    end

    private

    def cache_key
      [:logs, current_account.id, :count, request.query_string.parameterize].select(&:present?).join ":"
    end
  end
end