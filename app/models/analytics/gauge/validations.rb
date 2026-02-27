# frozen_string_literal: true

module Analytics
  class Gauge
    class Validations
      def initialize(account:, environment:, license_id: nil)
        @account     = account
        @environment = environment
        @license_id  = license_id
      end

      def counts
        event_type_ids = EventType.where(event: %w[license.validation.succeeded license.validation.failed])
                                  .ids
        return {} if
          event_type_ids.empty?

        scope = EventLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                    .where(
                                      event_type_id: event_type_ids,
                                      created_date: Date.current,
                                    )

        unless license_id.nil?
          scope = scope.where(
            resource_type: License.name,
            resource_id: license_id,
          )
        end

        rows = scope.group(Arel.sql('metadata.code.:String'))
                    .pluck(
                      Arel.sql('metadata.code.:String'),
                      Arel.sql('count()'),
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
