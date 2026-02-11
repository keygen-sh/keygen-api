# frozen_string_literal: true

module Analytics
  class IpsLeaderboardQuery < BaseQuery
    MAX_LIMIT = 100

    def initialize(account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current, limit: 10)
      @account     = account
      @environment = environment
      @start_date  = [start_date, 1.year.ago.to_date].max
      @end_date    = [Date.current, end_date].min
      @limit       = [limit, MAX_LIMIT].min
    end

    def call
      # FIXME(ezekg) move to request log model once we fully migrate to clickhouse
      rows = RequestLog::Clickhouse.where(account_id: account.id)
                                   .where(environment_id: environment&.id)
                                   .where(created_date: start_date..end_date)
                                   .where(is_deleted: 0)
                                   .where.not(ip: [nil, ''])
                                   .group(:ip)
                                   .order(Arel.sql('count DESC'))
                                   .limit(limit)
                                   .pluck(
                                     :ip,
                                     Arel.sql('count(*) AS count'),
                                   )

      rows.map do |(identifier, count)|
        Leaderboard::Entry.new(identifier:, count:)
      end
    end

    private

    attr_reader :account,
                :environment,
                :start_date,
                :end_date,
                :limit
  end
end
