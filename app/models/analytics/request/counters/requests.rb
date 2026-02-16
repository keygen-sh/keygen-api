# frozen_string_literal: true

module Analytics
  class Request
    module Counters
      class Requests
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count(start_date:, end_date:)
          binds = { account_id: account.id, environment_id: environment&.id, start_date:, end_date: }.compact
          res   = exec_sql([<<~SQL.squish, binds])
            SELECT
              created_date AS date,
              count(*) AS count
            FROM
              request_logs
            WHERE
              account_id = :account_id AND
              environment_id #{environment.nil? ? 'IS NULL' : '= :environment_id'} AND
              created_date BETWEEN :start_date AND :end_date AND
              is_deleted = 0
            GROUP BY
              created_date
            ORDER BY
              created_date ASC
          SQL

          res['data'].to_h { |(date, count)| [Date.parse(date), count] }
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
