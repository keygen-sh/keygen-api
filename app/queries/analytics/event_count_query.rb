# frozen_string_literal: true

module Analytics
  class EventCountQuery < BaseQuery
    Result = Data.define(:event, :count)

    def initialize(account:, environment:, event_types:, start_date:, end_date:)
      @account     = account
      @environment = environment
      @event_types = event_types
      @start_date  = [1.year.ago.to_date, start_date].max
      @end_date    = [end_date, Date.current].min
    end

    def call
      counts = fetch_event_log_count_by_event_type

      event_types.map do |event_type|
        Result.new(event: event_type.event, count: counts[event_type.id].to_i)
      end
    end

    private

    attr_reader :account,
                :environment,
                :event_types,
                :start_date,
                :end_date

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
