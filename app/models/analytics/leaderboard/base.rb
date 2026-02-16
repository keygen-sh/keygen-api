# frozen_string_literal: true

module Analytics
  module Leaderboard
    class Base
      include ActiveModel::Model
      include ActiveModel::Attributes

      Result = Data.define(:identifier, :count)

      MAX_LIMIT = 100

      attribute :account
      attribute :environment
      attribute :start_date, default: -> { 2.weeks.ago.to_date }
      attribute :end_date, default: -> { Date.current }
      attribute :limit, default: -> { 10 }

      validates :account, presence: true
      validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.year.ago.to_date } }
      validates :end_date, comparison: { less_than_or_equal_to: -> { Date.current } }
      validates :limit, numericality: { less_than_or_equal_to: MAX_LIMIT }

      def result
        @result ||= rows.map { |(identifier, count)| Result.new(identifier:, count:) }
      end

      private

      def rows
        res = exec_sql([query.squish, binds])

        res['data']
      end

      def query
        raise NotImplementedError
      end

      def binds
        { account_id:, environment_id:, start_date:, end_date:, limit: }.compact
      end

      def account_id     = account.id
      def environment_id = environment&.id

      def environment_clause
        environment.nil? ? 'IS NULL' : '= :environment_id'
      end

      def exec_sql(...)
        klass = RequestLog::Clickhouse

        klass.connection.execute(
          klass.sanitize_sql(...),
        )
      end
    end
  end
end
