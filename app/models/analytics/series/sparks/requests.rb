# frozen_string_literal: true

module Analytics
  class Series
    class Sparks
      class Requests
        METRICS = %w[requests.2xx requests.3xx requests.4xx requests.5xx].freeze

        def initialize(account:, environment:, realtime: true, **)
          @account     = account
          @environment = environment
          @realtime    = realtime
        end

        def metrics = METRICS
        def count(start_date:, end_date:)
          rows = RequestSpark.for_account(account)
                             .for_environment(environment)
                             .where(created_date: start_date..end_date)
                             .group(:created_date)
                             .pluck(
                               :created_date,
                               Arel.sql(%{sumIf(count, status >= 200 AND status < 300) AS "2xx"}),
                               Arel.sql(%{sumIf(count, status >= 300 AND status < 400) AS "3xx"}),
                               Arel.sql(%{sumIf(count, status >= 400 AND status < 500) AS "4xx"}),
                               Arel.sql(%{sumIf(count, status >= 500 AND status < 600) AS "5xx"}),
                             )

          counts = rows.each_with_object({}) do |(date, *counts), hash|
            METRICS.zip counts do |metric, count|
              hash[[metric, date]] = count
            end
          end

          # defer to gauge for a realtime count since sparks are nightly
          if realtime? && end_date.today?
            gauge = Analytics::Gauge.new(:requests, account:, environment:)

            gauge.measurements.each do |measurement|
              counts[[measurement.metric, end_date]] = measurement.count
            end
          end

          counts
        end

        private

        attr_reader :account,
                    :environment,
                    :realtime

        def realtime? = !!realtime
      end
    end
  end
end
