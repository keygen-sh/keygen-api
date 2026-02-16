# frozen_string_literal: true

module Analytics
  class EventNotFoundError < StandardError; end

  class Event
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Data.define(:event, :count)

    attribute :account
    attribute :environment
    attribute :pattern
    attribute :start_date, default: -> { 2.weeks.ago.to_date }
    attribute :end_date, default: -> { Date.current }

    validates :account, presence: true
    validates :pattern, presence: true
    validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.year.ago.to_date } }
    validates :end_date, comparison: { less_than_or_equal_to: -> { Date.current } }

    def self.call(pattern, account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current)
      event = new(pattern:, account:, environment:, start_date:, end_date:)

      raise EventNotFoundError, "invalid event pattern: #{pattern.inspect}" if
        event.event_types.empty?

      event.result
    end

    def result
      @result ||= build_results
    end

    def event_types
      @event_types ||= lookup_event_types
    end

    private

    def build_results
      counts = fetch_event_log_count_by_event_type

      event_types.map do |event_type|
        Result.new(event: event_type.event, count: counts[event_type.id].to_i)
      end
    end

    def lookup_event_types
      types = if pattern.end_with?('.*')
                EventType.where('event LIKE ?', "#{pattern.delete_suffix('.*')}.%")
              else
                EventType.where(event: pattern)
              end

      types.order(:event)
    end

    def fetch_event_log_count_by_event_type
      EventLog::Clickhouse.where(account_id: account.id)
                          .where(environment_id: environment&.id)
                          .where(created_date: start_date..end_date)
                          .where(event_type_id: event_types.pluck(:id))
                          .where(is_deleted: 0)
                          .group(:event_type_id)
                          .count
    end
  end
end
