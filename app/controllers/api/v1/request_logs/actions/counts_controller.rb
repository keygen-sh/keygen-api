# frozen_string_literal: true

module Api::V1::RequestLogs::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    def count
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        conn = ActiveRecord::Base.connection

        start_date = 13.days.ago.beginning_of_day
        end_date = Time.current
        sql = <<~SQL
          SELECT
            "request_logs"."created_at"::date AS date,
            COUNT(*) AS count
          FROM
            "request_logs"
          WHERE
            "request_logs"."account_id" = #{conn.quote current_account.id} AND
            (
              "request_logs"."created_at" >= #{conn.quote start_date} AND
              "request_logs"."created_at" <= #{conn.quote end_date}
            )
          GROUP BY
            "request_logs"."created_at"::date
        SQL

        rows = conn.execute sql.squish

        # Create zeroed out hash of dates then merge real counts (so we include dates with no data)
        dates = start_date.to_date..end_date.to_date

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
      [:logs, current_account.id, :count, Digest::SHA2.hexdigest(request.query_string)].join ":"
    end
  end
end