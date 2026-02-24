# frozen_string_literal: true

module Analytics
  class Series
    class Events
      def initialize(account:, environment:, event_pattern: nil, resource_type: nil, resource_id: nil)
        @account       = account
        @environment   = environment
        @event_pattern = event_pattern
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
                      .count

        # series expects [metric, date] => count
        mapping = event_types.index_by(&:id).transform_values(&:event)

        counts.each_with_object({}) do |((event_type_id, date), count), hash|
          hash[[mapping[event_type_id], date]] = count
        end
      end

      private

      attr_reader :account,
                  :environment,
                  :event_pattern,
                  :resource_type,
                  :resource_id

      def event_types    = @event_types ||= EventType.by_pattern(event_pattern)
      def event_type_ids = event_types.collect(&:id)
    end
  end
end
