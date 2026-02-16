# frozen_string_literal: true

module Analytics
  class UrlsLeaderboardQuery < BaseQuery
    Result = Data.define(:identifier, :count)

    MAX_LIMIT = 100

    def initialize(account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current, limit: 10)
      @account     = account
      @environment = environment
      @start_date  = [start_date, 1.year.ago.to_date].max
      @end_date    = [Date.current, end_date].min
      @limit       = [limit.to_i, MAX_LIMIT].min
    end

    def call
      binds = { account_id:, environment_id:, start_date:, end_date:, limit: }.compact
      res   = exec_sql([<<~SQL.squish, binds])
        SELECT
          concat(method, ' ', url) AS identifier,
          count(*) AS count
        FROM request_logs
        WHERE account_id = :account_id
          AND environment_id #{environment.nil? ? 'IS NULL' : '= :environment_id'}
          AND created_date BETWEEN :start_date AND :end_date
          AND is_deleted = 0
          AND url IS NOT NULL
          AND method IS NOT NULL
        GROUP BY identifier
        ORDER BY count DESC
        LIMIT :limit
      SQL

      res['data'].map do |(identifier, count)|
        Result.new(identifier:, count:)
      end
    end

    private

    attr_reader :account,
                :environment,
                :start_date,
                :end_date,
                :limit

    def account_id     = account.id
    def environment_id = environment&.id

    def exec_sql(...)
      klass = RequestLog::Clickhouse

      klass.connection.execute(
        klass.sanitize_sql(...),
      )
    end
  end
end
