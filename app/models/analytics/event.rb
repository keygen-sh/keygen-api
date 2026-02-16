# frozen_string_literal: true

module Analytics
  class EventNotFoundError < StandardError; end

  module Event
    extend self

    def call(pattern, account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current)
      event_types = lookup_event_types(pattern)

      raise EventNotFoundError, "invalid event pattern: #{pattern.inspect}" if
        event_types.empty?

      EventCountQuery.call(account:, environment:, event_types:, start_date:, end_date:)
    end

    private

    def lookup_event_types(pattern)
      event_types = if pattern.end_with?('.*')
                      EventType.where('event LIKE ?', "#{pattern.delete_suffix('.*')}.%")
                    else
                      EventType.where(event: pattern)
                    end

      event_types.order(:event)
    end
  end
end
