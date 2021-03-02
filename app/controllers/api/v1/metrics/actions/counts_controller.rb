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

      # TODO(ezekg) Cache this in-memory on event type model?
      event_types = EventType.select(:id, :event)
      event_params = params[:metrics]
      event_type_ids = []

      # This not only blocks counts for invalid event types but it is also our
      # first defense from SQL injection below
      if event_params.present?
        valid_events = event_types.map(&:event)

        if (event_params - valid_events).any?
          diff = event_params - valid_events

          raise Keygen::Error::InvalidScopeError.new(parameter: "metrics"), "one or more metric is invalid: #{diff.join(', ')}"
        end

        # Select the event types from the event params
        selected_events = valid_events & event_params
        event_type_ids = event_types
          .select { |e| selected_events.include?(e.event) }
          .map(&:id)
      end

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        conn = ActiveRecord::Base.connection

        start_date = 13.days.ago.beginning_of_day
        end_date = Time.current
        sql =
          if event_type_ids.any?
            <<~SQL
              SELECT
                "metrics"."created_at"::date AS date,
                COUNT(*) AS count
              FROM
                "metrics"
              WHERE
                "metrics"."account_id" = #{conn.quote current_account.id} AND
                (
                  "metrics"."created_at" >= #{conn.quote start_date} AND
                  "metrics"."created_at" <= #{conn.quote end_date}
                ) AND
                "metrics"."event_type_id" IN (#{event_type_ids.map { |m| conn.quote(m) }.join(", ")})
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
                  "metrics"."created_at" >= #{conn.quote start_date} AND
                  "metrics"."created_at" <= #{conn.quote end_date}
                )
              GROUP BY
                "metrics"."created_at"::date
            SQL
          end

        rows = conn.execute sql.squish

        # Create zeroed out hash of dates then merge real counts (so we include dates with no data)
        dates = start_date.to_date..end_date.to_date

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