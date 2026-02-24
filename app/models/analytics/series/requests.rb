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
                                       :created_date,
                                       Arel.sql(%{countIf(status IN ('200', '201', '202', '204')) AS "2xx"}),
                                       Arel.sql(%{countIf(status IN ('301', '302', '303', '304', '307', '308')) AS "3xx"}),
                                       Arel.sql(%{countIf(status IN ('400', '401', '402', '403', '404', '405', '406', '409', '410', '413', '422', '429')) AS "4xx"}),
                                       Arel.sql(%{countIf(status IN ('500', '501', '502', '503', '504')) AS "5xx"}),
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
