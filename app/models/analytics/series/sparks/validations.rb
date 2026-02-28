# frozen_string_literal: true

module Analytics
  class Series
    class Sparks
      class Validations
        def initialize(account:, environment:, license_id: nil, realtime: true, **)
          @account     = account
          @environment = environment
          @license_id  = license_id
          @realtime    = realtime
        end

        def metrics = LicenseValidation::CODES.map { "validations.#{it.underscore.dasherize}" }
        def count(start_date:, end_date:)
          scope = LicenseValidationSpark.for_account(account)
                                        .for_environment(environment)
                                        .where(
                                          created_date: start_date..end_date,
                                        )

          unless license_id.nil?
            scope = scope.where(license_id:)
          end

          rows = scope.group(:created_date, :validation_code)
                      .pluck(
                        :created_date,
                        :validation_code,
                        Arel.sql('sum(count)'),
                      )

          counts = rows.each_with_object({}) do |(date, code, count), hash|
            hash[["validations.#{code.underscore.dasherize}", date]] = count
          end

          # defer to gauge for a realtime count since sparks are nightly
          if realtime? && end_date.today?
            gauge = Analytics::Gauge.new(:validations, account:, environment:, license_id:)

            gauge.measurements.each do |measurement|
              counts[[measurement.metric, end_date]] = measurement.count
            end
          end

          counts
        end

        private

        attr_reader :account,
                    :environment,
                    :license_id,
                    :realtime

        def realtime? = !!realtime
      end
    end
  end
end
