# frozen_string_literal: true

module Analytics
  class EventCountQuery < BaseQuery
    Result = Data.define(:event, :count)

    def initialize(account:, environment:, event:, start_date:, end_date:)
      @account     = account
      @environment = environment
      @event       = event
      @start_date  = [1.year.ago.to_date, start_date].max
      @end_date    = [end_date, Date.current].min
    end

    def call
      counts = fetch_event_log_count_by_event_type

      event_type_ids.map do |event_type_id|
        event = EventType.lookup_event_by_id(event_type_id)
        count = counts[event_type_id].to_i

        Result.new(event:, count:)
      end
    end

    private

    attr_reader :account,
                :environment,
                :event,
                :start_date,
                :end_date

    def fetch_event_log_count_by_event_type
      EventLog::Clickhouse.where(account_id: account.id)
                          .where(environment_id: environment&.id)
                          .where(created_date: start_date..end_date)
                          .where(event_type_id: event_type_ids)
                          .where(is_deleted: 0)
                          .group(:event_type_id)
                          .count
    end

    def event_type_ids = @event_type_ids ||= begin
      event_types = if event.end_with?('.*')
                      EventType.where('event LIKE ?', "#{event.delete_suffix('.*')}.%")
                    else
                      EventType.where(event:)
                    end

      event_types.order(:event)
                 .pluck(:id)
    end
  end
end
