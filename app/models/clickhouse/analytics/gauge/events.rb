# frozen_string_literal: true

module Analytics
  class Gauge
    class Events
      def initialize(account:, environment:, event:)
        @account     = account
        @environment = environment
        @event       = event
      end

      def metrics = event_types.map { "events.#{it.event.parameterize}" }
      def count
        rows = account.event_logs.for_environment(environment)
                                 .where(created_date: Date.current, event_type_id: event_type_ids)
                                 .group(:event_type_id)
                                 .pluck(
                                   :event_type_id,
                                   Arel.sql('count()'),
                                 )

        rows.each_with_object({}) do |(event_type_id, count), hash|
          metric = mapping[event_type_id]

          hash[metric] = count
        end
      end

      private

      attr_reader :account,
                  :environment,
                  :event

      def event_types    = @event_types ||= EventType.by_pattern(event)
      def event_type_ids = event_types.collect(&:id)
      def mapping        = @mapping ||= event_types.index_by(&:id).transform_values { "events.#{it.event.parameterize}" }
    end
  end
end
