# frozen_string_literal: true

module Analytics
  module Leaderboard
    class Licenses < Base
      private

      def query
        <<~SQL
          SELECT
            resource_id AS identifier,
            count(*) AS count
          FROM request_logs
          WHERE account_id = :account_id
            AND environment_id #{environment_clause}
            AND created_date BETWEEN :start_date AND :end_date
            AND is_deleted = 0
            AND resource_type = 'License'
            AND resource_id IS NOT NULL
          GROUP BY resource_id
          ORDER BY count DESC
          LIMIT :limit
        SQL
      end
    end
  end
end
