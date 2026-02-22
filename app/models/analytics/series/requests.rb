# frozen_string_literal: true

module Analytics
  class Series
    class Requests
      METRICS = %w[requests.2xx requests.3xx requests.4xx requests.5xx].freeze

      def initialize(account:, environment:, **)
        @account     = account
        @environment = environment
      end

      def metrics = METRICS

      def count(start_date:, end_date:)
        rows = RequestLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                     .where(created_date: start_date..end_date, is_deleted: 0)
                                     .order(:created_date)
                                     .group(:created_date)
                                     .pluck(
                                       Arel.sql('created_date'),
                                       Arel.sql("countIf(startsWith(status, '2'))"),
                                       Arel.sql("countIf(startsWith(status, '3'))"),
                                       Arel.sql("countIf(startsWith(status, '4'))"),
                                       Arel.sql("countIf(startsWith(status, '5'))"),
                                     )

        # series expects [metric, date] => count
        rows.each_with_object({}) do |(date, *counts), hash|
          METRICS.zip counts do |metric, count|
            hash[[metric, date]] = count
          end
        end
      end

      private

      attr_reader :account,
                  :environment
    end
  end
end
