# frozen_string_literal: true

module Analytics
  module Leaderboard
    class Urls < Base
      private

      def query
        <<~SQL
          SELECT
            concat(method, ' ', url) AS identifier,
            count(*) AS count
          FROM request_logs
          WHERE account_id = :account_id
            AND environment_id #{environment_clause}
            AND created_date BETWEEN :start_date AND :end_date
            AND is_deleted = 0
            AND url IS NOT NULL
            AND method IS NOT NULL
          GROUP BY identifier
          ORDER BY count DESC
          LIMIT :limit
        SQL
      end
    end
  end
end
