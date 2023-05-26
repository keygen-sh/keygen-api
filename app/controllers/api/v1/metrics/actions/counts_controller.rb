# frozen_string_literal: true

module Api::V1::Metrics::Actions
  class CountsController < Api::V1::BaseController
    has_scope(:metrics, type: :array) { |c, s, v| s.with_events(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    def count
      authorize! with: MetricPolicy

      event_params = params[:metrics]
      event_type_ids = []

      # Filter out invalid event types
      if event_params.present?
        event_types = EventType.select(:id, :event)
        valid_events = event_types.map(&:event)

        if (event_params - valid_events).any?
          diff = event_params - valid_events

          raise Keygen::Error::InvalidParameterError.new(parameter: "metrics"), "one or more metric is invalid: #{diff.join(', ')}"
        end

        # Select the event types from the event params
        selected_events = valid_events & event_params
        event_type_ids = event_types
          .select { |e| selected_events.include?(e.event) }
          .map(&:id)
      end

      json = Rails.cache.fetch(cache_key, expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        start_date = Date.current - 13.days
        end_date   = Date.current

        conn = ActiveRecord::Base.connection
        rows =
          if event_type_ids.any?
            conn.execute(
              Metric.sanitize_sql([<<~SQL, account_id: current_account.id, event_type_ids:, start_date:, end_date:])
                SELECT
                  sum(m.count) AS count,
                  series.date  AS period
                FROM
                  generate_series(date :start_date, date :end_date, interval '1 day') AS series (date)
                LEFT JOIN LATERAL
                  (
                    SELECT
                      count(*)     AS count,
                      created_date AS date,
                      event_type_id,
                      account_id
                    FROM
                      metrics
                    WHERE
                      account_id     = :account_id AND
                      created_date   = series.date AND
                      event_type_id IN (
                        :event_type_ids
                      )
                    GROUP BY
                      event_type_id,
                      account_id,
                      date
                  ) AS m USING (date)
                GROUP BY
                  series.date;
              SQL
            )
          else
            conn.execute(
              Metric.sanitize_sql([<<~SQL, account_id: current_account.id, start_date:, end_date:])
                SELECT
                  coalesce(m.count, 0) AS count,
                  series.date          AS period
                FROM
                  generate_series(date :start_date, date :end_date, interval '1 day') AS series (date)
                LEFT JOIN LATERAL
                  (
                    SELECT
                      count(*)     AS count,
                      created_date AS date,
                      account_id
                    FROM
                      metrics
                    WHERE
                      account_id   = :account_id AND
                      created_date = series.date
                    GROUP BY
                      account_id,
                      date
                  ) AS m USING (date);
              SQL
            )
          end

        {
          meta: rows.map { [_1['period'].strftime('%Y-%m-%d'), _1['count'].to_i] }
                    .to_h,
        }
      end

      render json: json
    end

    private

    def cache_key
      [:metrics, current_account.id, :count, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end
