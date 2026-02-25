# frozen_string_literal: true

module Analytics
  class Series
    class Sparks
      MAPPING = {
        active_licensed_users: ActiveLicensedUserSpark,
        machines: MachineSpark,
        licenses: LicenseSpark,
        users: UserSpark,
        alus: ActiveLicensedUserSpark, # alias
      }

      def initialize(account:, environment:, metric:, realtime: true, **)
        @account     = account
        @environment = environment
        @metric      = metric.to_sym
        @realtime    = realtime
      end

      def metrics
        return [] unless MAPPING.key?(metric)

        [metric]
      end

      def count(start_date:, end_date:)
        spark = MAPPING[metric]
        rows  = spark.for_account(account)
                     .for_environment(environment)
                     .where(created_date: start_date..end_date)
                     .group(:created_date)
                     .pluck(
                       :created_date,
                       Arel.sql('argMax(count, created_at)'),
                     )

        counts = rows.each_with_object({}) do |(date, count), hash|
          hash[[metric, date]] = count
        end

        # defer to gauges for a realtime count since sparks are nightly
        if realtime? && end_date.today?
          gauge = Analytics::Gauge.new(metric, account:, environment:)

          counts[[metric, end_date]] = gauge.count
        end

        counts
      end

      private

      attr_reader :account,
                  :environment,
                  :metric,
                  :realtime

      def realtime? = !!realtime
    end
  end
end
