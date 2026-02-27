# frozen_string_literal: true

module Analytics
  class Series
    class Validations
      def initialize(account:, environment:, license_id: nil, **)
        @account     = account
        @environment = environment
        @license_id  = license_id
      end

      # FIXME(ezekg) add caching
      def metrics = @metrics ||= begin
        codes = LicenseValidationSpark.for_account(account)
                                      .for_environment(environment)
                                      .distinct
                                      .pluck(:validation_code)

        codes.map { "validations.#{it.underscore.dasherize}" }
      end

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

        rows.each_with_object({}) do |(date, code, count), hash|
          hash[["validations.#{code.underscore.dasherize}", date]] = count
        end
      end

      private

      attr_reader :account,
                  :environment,
                  :license_id
    end
  end
end
