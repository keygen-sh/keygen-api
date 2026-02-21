# frozen_string_literal: true

module Analytics
  class Series
    module Counters
      class Events
        def initialize(account:, environment:, pattern: nil, resource_type: nil, resource_id: nil)
          @account       = account
          @environment   = environment
          @pattern       = pattern
          @resource_type = resource_type
          @resource_id   = resource_id
        end

        def metrics = @metrics ||= event_types.map(&:event)

        def count(start_date:, end_date:)
          scope = EventLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                      .where(created_date: start_date..end_date)
                                      .where(event_type_id: event_type_ids)
                                      .where(is_deleted: 0)

          if resource_type.present? && resource_id.present?
            scope = scope.where(
              resource_type: resource_type.underscore.classify,
              resource_id:,
            )
          end

          counts = scope.group(:event_type_id, :created_date)
                        .order(:created_date)
                        .count

          counts.each_with_object({}) do |((event_type_id, date), cnt), hash|
            hash[[event_type_map[event_type_id], date]] = cnt
          end
        end

        private

        attr_reader :account, :environment, :pattern, :resource_type, :resource_id

        def event_types    = @event_types ||= EventType.by_pattern(pattern)
        def event_type_ids = event_types.collect(&:id)
        def event_type_map = @event_type_map ||= event_types.to_h { [_1.id, _1.event] }
      end
    end
  end
end
