# frozen_string_literal: true

module Analytics
  class Series
    module Counters
      class Events
        Bucket = Data.define(:event, :date, :count)
        Group  = Data.define(:key, :label)

        def initialize(account:, environment:, pattern: nil, resource_type: nil, resource_id: nil)
          @account       = account
          @environment   = environment
          @pattern       = pattern
          @resource_type = resource_type
          @resource_id   = resource_id
        end

        def groups = @groups ||= event_types.map { Group.new(key: _1.id, label: _1.event) }

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

          scope.group(:event_type_id, :created_date)
               .order(:created_date)
               .count
        end

        def count_key(group:, date:) = [group.key, date]
        def bucket(group:, date:, count:) = Bucket.new(event: group.label, date:, count:)

        def cache_key = "#{pattern}:#{resource_type}:#{resource_id}"

        def validate(errors)
          errors.add(:pattern, :blank, message: "can't be blank") if pattern.blank?
          errors.add(:pattern, :invalid, message: 'is invalid') if pattern.present? && event_types.empty?
        end

        private

        attr_reader :account, :environment, :pattern, :resource_type, :resource_id

        def event_types    = @event_types ||= EventType.by_pattern(pattern)
        def event_type_ids = event_types.collect(&:id)
      end
    end
  end
end
