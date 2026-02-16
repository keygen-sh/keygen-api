# frozen_string_literal: true

module Analytics
  class Leaderboard
    module Counters
      module Urls
        QUERY = <<~SQL.squish
          SELECT
            concat(method, ' ', url) AS identifier,
            count(*) AS count
          FROM request_logs
          WHERE account_id = :account_id
            AND environment_id %{environment_clause}
            AND created_date BETWEEN :start_date AND :end_date
            AND is_deleted = 0
            AND url IS NOT NULL
            AND method IS NOT NULL
          GROUP BY identifier
          ORDER BY count DESC
          LIMIT :limit
        SQL

        def self.count(account:, environment:, start_date:, end_date:, limit:)
          environment_clause = environment.nil? ? 'IS NULL' : '= :environment_id'

          binds = { account_id: account.id, environment_id: environment&.id, start_date:, end_date:, limit: }.compact
          query = format(QUERY, environment_clause:)
          res   = exec_sql([query, binds])

          res['data']
        end

        def self.exec_sql(...)
          RequestLog::Clickhouse.connection.execute(
            RequestLog::Clickhouse.sanitize_sql(...),
          )
        end
      end
    end
  end
end
