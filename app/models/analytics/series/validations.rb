# frozen_string_literal: true

module Analytics
  class Series
    class Validations
      METRICS = %w[
        validations.banned
        validations.checksum-scope-mismatch
        validations.checksum-scope-required
        validations.components-scope-empty
        validations.components-scope-mismatch
        validations.components-scope-required
        validations.entitlements-missing
        validations.entitlements-scope-empty
        validations.environment-scope-mismatch
        validations.environment-scope-required
        validations.expired
        validations.fingerprint-scope-empty
        validations.fingerprint-scope-mismatch
        validations.fingerprint-scope-required
        validations.heartbeat-dead
        validations.heartbeat-not-started
        validations.machine-scope-mismatch
        validations.machine-scope-required
        validations.no-machine
        validations.no-machines
        validations.not-found
        validations.overdue
        validations.policy-scope-mismatch
        validations.policy-scope-required
        validations.product-scope-mismatch
        validations.product-scope-required
        validations.suspended
        validations.too-many-cores
        validations.too-many-machines
        validations.too-many-processes
        validations.too-many-users
        validations.too-much-disk
        validations.too-much-memory
        validations.user-scope-mismatch
        validations.user-scope-required
        validations.valid
        validations.version-scope-mismatch
        validations.version-scope-required
      ].freeze

      def initialize(account:, environment:, license_id: nil, realtime: true, **)
        @account     = account
        @environment = environment
        @license_id  = license_id
        @realtime    = realtime
      end

      def metrics = METRICS

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
          gauge = Analytics::Gauge::Validations.new(account:, environment:, license_id:)

          gauge.count.each do |metric, count|
            counts[[metric, end_date]] = count
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
