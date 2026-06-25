# frozen_string_literal: true

module Analytics
  class Series
    class Sparks
      class Events
        def initialize(account:, environment:, event:, realtime: true, **)
          @account     = account
          @environment = environment
          @event       = event
          @realtime    = realtime
        end

        def metrics = event_types.map { "events.#{it.event.parameterize}" }
        def count(start_date:, end_date:)
          rows = EventSpark.for_account(account)
                           .for_environment(environment)
                           .where(created_date: start_date..end_date, event_type_id: event_type_ids)
                           .group(:created_date, :event_type_id)
                           .pluck(
                             :created_date,
                             :event_type_id,
                             Arel.sql('sum(count)'),
                           )

          counts = rows.each_with_object({}) do |(date, event_type_id, count), hash|
            metric = mapping[event_type_id]

            hash[[metric, date]] = count
          end

          # defer to gauge for a realtime count since sparks are nightly
          if realtime? && end_date.today?
            gauge = Analytics::Gauge.new(:events, account:, environment:, event:)

            gauge.measurements.each do |measurement|
              counts[[measurement.metric, end_date]] = measurement.count
            end
          end

          counts
        end

        private

        attr_reader :account,
                    :environment,
                    :event,
                    :realtime

        def realtime? = !!realtime

        def event_types    = @event_types ||= EventType.by_pattern(event)
        def event_type_ids = event_types.collect(&:id)
        def mapping        = @mapping ||= event_types.index_by(&:id).transform_values { "events.#{it.event.parameterize}" }
      end
    end
  end
end
