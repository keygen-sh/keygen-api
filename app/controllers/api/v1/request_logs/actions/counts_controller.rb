# frozen_string_literal: true

module Api::V1::RequestLogs::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    def count
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        conn       = ActiveRecord::Base.connection
        start_date = Date.current - 13.days
        end_date   = Date.current

        rows = conn.execute(<<~SQL.squish)
          SELECT
            coalesce(logs.count, 0) AS count,
            period
          FROM
            generate_series(date #{conn.quote start_date}, date #{conn.quote end_date}, interval '1 day') AS period (date)
          LEFT JOIN LATERAL
            (
              SELECT
                count(*)     AS count,
                created_date AS date,
                account_id
              FROM
                request_logs
              WHERE
                account_id   = #{conn.quote current_account.id} AND
                created_date = period.date
              GROUP BY
                account_id,
                date
            ) AS logs USING (date);
        SQL

        {
          meta: rows.map { [_1['period'].strftime('%Y-%m-%d'), _1['count']] }
                    .to_h,
        }
      end

      render json: json
    end

    private

    def cache_key
      [:logs, current_account.id, :count, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end
