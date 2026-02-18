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
          RequestLog::Clickhouse.where(account_id: account.id)
                                .where(environment_id: environment&.id)
                                .where(created_date: start_date..end_date)
                                .where.not(ip: [nil, ''])
                                .where(is_deleted: 0)
                                .group(:ip)
                                .order(Arel.sql('count(*) DESC'))
                                .limit(limit)
                                .pluck(:ip, Arel.sql('count(*)'))
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
