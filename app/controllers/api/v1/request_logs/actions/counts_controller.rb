# frozen_string_literal: true

module Api::V1::RequestLogs::Actions
  class CountsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    def count
      authorize! with: RequestLogPolicy

      json = Rails.cache.fetch(cache_key, expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        start_date = Date.current - 13.days
        end_date   = Date.current

        # FIXME(ezekg) Counts should take into account the current environment. Need to update
        #              indexes and all that jazz to also include the environment_id.
        conn = ActiveRecord::Base.connection
        rows = conn.execute(
          RequestLog.sanitize_sql([<<~SQL.squish, account_id: current_account.id, start_date:, end_date:])
            SELECT
              coalesce(logs.count, 0) AS count,
              series.date             AS period
            FROM
              generate_series(date :start_date, date :end_date, interval '1 day') AS series (date)
            LEFT JOIN LATERAL
              (
                SELECT
                  count(*)     AS count,
                  created_date AS date,
                  account_id
                FROM
                  request_logs
                WHERE
                  account_id   = :account_id AND
                  created_date = series.date
                GROUP BY
                  account_id,
                  date
              ) AS logs USING (date);
          SQL
        )

        {
          meta: rows.map { [it['period'].strftime('%Y-%m-%d'), it['count'].to_i] }
                    .to_h,
        }
      end

      render json: json
    end

    private

    def cache_key
      [:logs, current_account.id, :count, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end

    def require_ee!
      super(entitlements: %i[request_logs])
    end
  end
end
