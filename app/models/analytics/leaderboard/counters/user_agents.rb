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
          RequestLog::Clickhouse.where(account_id: account.id)
                                .where(environment_id: environment&.id)
                                .where(created_date: start_date..end_date)
                                .where(is_deleted: 0)
                                .where.not(user_agent: [nil, ''])
                                .group(:user_agent)
                                .order(Arel.sql('count(*) DESC'))
                                .limit(limit)
                                .pluck(:user_agent, Arel.sql('count(*)'))
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
