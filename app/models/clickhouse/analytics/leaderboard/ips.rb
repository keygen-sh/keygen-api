# frozen_string_literal: true

module Analytics
  class Leaderboard
    class Ips
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def count(start_date:, end_date:, limit:)
        scope = account.request_logs.for_environment(environment)
                                    .where(created_date: start_date..end_date)
                                    .where.not(ip: ['', nil])
                                    .order(Arel.sql('count_all DESC'))
                                    .limit(limit)

        scope.group(:ip)
             .count
      end

      private

      attr_reader :account, :environment
    end
  end
end
