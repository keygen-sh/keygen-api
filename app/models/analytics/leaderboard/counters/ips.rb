# frozen_string_literal: true

module Analytics
  class Leaderboard
    module Counters
      class Ips
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count(start_date:, end_date:, limit:)
          binds = { account_id: account.id, environment_id: environment&.id, start_date:, end_date:, limit: }.compact
          res   = exec_sql([<<~SQL.squish, binds])
            SELECT
              ip AS identifier,
              count(*) AS count
            FROM
              request_logs
            WHERE
              account_id = :account_id AND
              environment_id #{environment.nil? ? 'IS NULL' : '= :environment_id'} AND
              created_date BETWEEN :start_date AND :end_date AND
              ip IS NOT NULL AND ip != '' AND
              is_deleted = 0
            GROUP BY
              ip
            ORDER BY
              count DESC
            LIMIT
              :limit
          SQL

          res['data']
        end

        private

        attr_reader :account, :environment

        def exec_sql(...)
          RequestLog::Clickhouse.connection.execute(
            RequestLog::Clickhouse.sanitize_sql(...),
          )
        end
      end
    end
  end
end
