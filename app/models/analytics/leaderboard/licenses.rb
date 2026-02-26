# frozen_string_literal: true

module Analytics
  class Leaderboard
    class Licenses
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def count(start_date:, end_date:, limit:)
        scope = RequestLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                      .where(created_date: start_date..end_date)
                                      .where(resource_type: 'License')
                                      .where.not(resource_id: nil)
                                      .order(Arel.sql('count_all DESC'))
                                      .limit(limit)

        scope.group(:resource_id)
             .count
      end

      private

      attr_reader :account, :environment
    end
  end
end
