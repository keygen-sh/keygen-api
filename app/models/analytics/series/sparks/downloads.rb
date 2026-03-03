# frozen_string_literal: true

module Analytics
  class Series
    class Sparks
      class Downloads
        def initialize(account:, environment:, product_id: nil, package_id: nil, release_id: nil, realtime: true, **)
          @account     = account
          @environment = environment
          @product_id  = product_id
          @package_id  = package_id
          @release_id  = release_id
          @realtime    = realtime
        end

        def metrics = %w[downloads]
        def count(start_date:, end_date:)
          scope = ReleaseDownloadSpark.for_account(account)
                                      .for_environment(environment)
                                      .where(
                                        created_date: start_date..end_date,
                                      )

          unless product_id.nil?
            scope = scope.where(product_id:)
          end

          unless package_id.nil?
            scope = scope.where(package_id:)
          end

          unless release_id.nil?
            scope = scope.where(release_id:)
          end

          rows = scope.group(:created_date)
                      .pluck(
                        :created_date,
                        Arel.sql('sum(count)'),
                      )

          counts = rows.each_with_object({}) do |(date, count), hash|
            hash[['downloads', date]] = count
          end

          # defer to gauge for a realtime count since sparks are nightly
          if realtime? && end_date.today?
            gauge = Analytics::Gauge.new(:downloads, account:, environment:, product_id:, package_id:, release_id:)

            gauge.measurements.each do |measurement|
              counts[[measurement.metric, end_date]] = measurement.count
            end
          end

          counts
        end

        private

        attr_reader :account,
                    :environment,
                    :product_id,
                    :package_id,
                    :release_id,
                    :realtime

        def realtime? = !!realtime
      end
    end
  end
end
