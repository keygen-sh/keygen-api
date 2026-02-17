# frozen_string_literal: true

module Analytics
  class Leaderboard
    module Counters
      class Licenses
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count(start_date:, end_date:, limit:)
          binds = { account_id: account.id, environment_id: environment&.id, start_date:, end_date:, limit: }.compact
          res   = exec_sql(<<~SQL.squish, **binds)
            SELECT
              resource_id AS identifier,
              count(*)    AS count
            FROM request_logs
            WHERE account_id = :account_id
              AND environment_id #{environment.nil? ? 'IS NULL' : '= :environment_id'}
              AND created_date BETWEEN :start_date AND :end_date
              AND is_deleted = 0
              AND resource_type = 'License'
              AND resource_id IS NOT NULL
            GROUP BY resource_id
            ORDER BY count DESC
            LIMIT :limit
          SQL

          res.rows
        end

        private

        attr_reader :account, :environment

        def exec_sql(sql, **binds)
          RequestLog::Clickhouse.connection.exec_query(
            RequestLog::Clickhouse.sanitize_sql([sql, binds]),
          )
        end
      end
    end
  end
end
