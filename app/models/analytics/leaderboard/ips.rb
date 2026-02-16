# frozen_string_literal: true

module Analytics
  module Leaderboard
    class Ips < Base
      private

      def query
        <<~SQL
          SELECT
            ip AS identifier,
            count(*) AS count
          FROM request_logs
          WHERE account_id = :account_id
            AND environment_id #{environment_clause}
            AND created_date BETWEEN :start_date AND :end_date
            AND is_deleted = 0
            AND ip IS NOT NULL
            AND ip != ''
          GROUP BY ip
          ORDER BY count DESC
          LIMIT :limit
        SQL
      end
    end
  end
end
