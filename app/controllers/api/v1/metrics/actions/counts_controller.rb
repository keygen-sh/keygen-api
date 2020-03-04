# frozen_string_literal: true

module Api::V1::Metrics::Actions
  class CountsController < Api::V1::BaseController
    has_scope :metrics, type: :array

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # GET /metrics/actions/count
    def count
      authorize Metric

      metrics = params[:metrics]
      if metrics.present? && (metrics - Metric::METRIC_TYPES).any?
        diff = metrics - Metric::METRIC_TYPES

        raise Keygen::Error::InvalidScopeError.new(parameter: "metrics"), "one or more metric is invalid: #{diff.join(', ')}"
      end

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        conn = ActiveRecord::Base.connection

        dates = (13.days.ago.to_date..Date.today).map{ |date| date }
        sql =
          if metrics.present?
            <<~SQL
              SELECT
                "metrics"."created_at"::date AS date,
                COUNT(*) AS count
              FROM
                "metrics"
              WHERE
                "metrics"."account_id" = #{conn.quote current_account.id} AND
                "metrics"."metric" IN (#{metrics.map { |m| conn.quote(m) }.join(", ")}) AND
                (
                  "metrics"."created_at" >= #{conn.quote dates.first.beginning_of_day} AND
                  "metrics"."created_at" <= #{conn.quote dates.last.end_of_day}
                )
              GROUP BY
                "metrics"."created_at"::date
            SQL
          else
            <<~SQL
              SELECT
                "metrics"."created_at"::date AS date,
                COUNT(*) AS count
              FROM
                "metrics"
              WHERE
                "metrics"."account_id" = #{conn.quote current_account.id} AND
                (
                  "metrics"."created_at" >= #{conn.quote dates.first.beginning_of_day} AND
                  "metrics"."created_at" <= #{conn.quote dates.last.end_of_day}
                )
              GROUP BY
                "metrics"."created_at"::date
            SQL
          end

        rows = conn.execute sql.squish

        # Create zeroed out hash of dates then merge real counts (so we include dates with no data)
        {
          meta: dates.map { |d| [d.strftime("%Y-%m-%d"), 0] }.to_h
            .merge(
              rows.map { |r| r.fetch_values("date", "count") }.to_h
            )
        }
      end

      render json: json
    end

    private

    def cache_key
      [:metrics, current_account.id, :count, request.query_string.parameterize].select(&:present?).join ":"
    end
  end
end