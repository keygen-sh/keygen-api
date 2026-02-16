# frozen_string_literal: true

module Analytics
  module Leaderboard
    class UserAgents < Base
      private

      def query
        <<~SQL
          SELECT
            user_agent AS identifier,
            count(*) AS count
          FROM request_logs
          WHERE account_id = :account_id
            AND environment_id #{environment_clause}
            AND created_date BETWEEN :start_date AND :end_date
            AND is_deleted = 0
            AND user_agent IS NOT NULL
            AND user_agent != ''
          GROUP BY user_agent
          ORDER BY count DESC
          LIMIT :limit
        SQL
      end
    end
  end
end
