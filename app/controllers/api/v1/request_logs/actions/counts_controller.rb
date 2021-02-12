# frozen_string_literal: true

module Api::V1::RequestLogs::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    def count
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        conn = ActiveRecord::Base.connection

        dates = 13.days.ago.to_date..Time.current.to_date
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

    def top_urls_by_volume
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        conn = ActiveRecord::Base.connection

        start_date = 13.days.ago.beginning_of_day
        end_date = Time.current.end_of_day
        sql = <<~SQL
          SELECT
            "request_logs"."url" AS url,
            COUNT(*) AS count
          FROM
            "request_logs"
          WHERE
            "request_logs"."account_id" = #{conn.quote current_account.id} AND
            "request_logs"."url" IS NOT NULL AND
            (
              "request_logs"."created_at" >= #{conn.quote start_date} AND
              "request_logs"."created_at" <= #{conn.quote end_date}
            )
          GROUP BY
            "request_logs"."url"
          ORDER BY
            count DESC
          LIMIT
            10
        SQL

        rows = conn.execute sql.squish

        json = {
          meta: rows.map { |r| r.fetch_values('url', 'count') }.to_h,
        }
      end

      render json: json
    end

    def top_ips_by_volume
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        conn = ActiveRecord::Base.connection

        start_date = 13.days.ago.beginning_of_day
        end_date = Time.current.end_of_day
        sql = <<~SQL
          SELECT
            "request_logs"."ip" AS ip,
            COUNT(*) AS count
          FROM
            "request_logs"
          WHERE
            "request_logs"."account_id" = #{conn.quote current_account.id} AND
            "request_logs"."ip" IS NOT NULL AND
            (
              "request_logs"."created_at" >= #{conn.quote start_date} AND
              "request_logs"."created_at" <= #{conn.quote end_date}
            )
          GROUP BY
            "request_logs"."ip"
          ORDER BY
            count DESC
          LIMIT
            10
        SQL

        rows = conn.execute sql.squish

        json = {
          meta: rows.map { |r| r.fetch_values('ip', 'count') }.to_h,
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