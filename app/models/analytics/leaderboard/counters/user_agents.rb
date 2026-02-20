# frozen_string_literal: true

module Analytics
  class Leaderboard
    module Counters
      class UserAgents
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count(start_date:, end_date:, limit:)
          scope = RequestLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                        .where(created_date: start_date..end_date, is_deleted: 0)
                                        .where.not(user_agent: ['', nil])
                                        .order(Arel.sql('count_all DESC'))
                                        .limit(limit)

          scope.group(:user_agent)
               .count
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
