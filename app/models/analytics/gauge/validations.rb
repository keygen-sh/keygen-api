# frozen_string_literal: true

module Analytics
  class Gauge
    class Validations
      def initialize(account:, environment:, license_id: nil)
        @account     = account
        @environment = environment
        @license_id  = license_id
      end

      def metrics = Analytics::Series::Sparks::Validations::METRICS
      def count
        event_type_ids = EventType.by_pattern('license.validation.*')
                                  .collect(&:id)
        return {} if
          event_type_ids.empty?

        scope = EventLog::Clickhouse.for_account(account)
                                    .for_environment(environment)
                                    .where(
                                      event_type_id: event_type_ids,
                                      created_date: Date.current,
                                    )
                                    .where(
                                      Arel.sql('metadata.code IS NOT NULL'),
                                    )

        unless license_id.nil?
          scope = scope.where(
            resource_type: License.name,
            resource_id: license_id,
          )
        end

        rows = scope.group(Arel.sql('validation_code'))
                    .pluck(
                      Arel.sql('metadata.code.:String AS validation_code'),
                      Arel.sql('count() AS count'),
                    )

        rows.each_with_object({}) do |(code, count), hash|
          hash["validations.#{code.underscore.dasherize}"] = count
        end
      end

      private

      attr_reader :account, :environment, :license_id
    end
  end
end
