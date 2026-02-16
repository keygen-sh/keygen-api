# frozen_string_literal: true

module Analytics
  class Activity
    module Counters
      module EventTypes
        def self.count(account:, environment:, resource_type:, resource_id:, event_type_ids:, start_date:, end_date:)
          scope = EventLog::Clickhouse.where(account_id: account.id)
                                      .where(environment_id: environment&.id)
                                      .where(created_date: start_date..end_date)
                                      .where(event_type_id: event_type_ids)
                                      .where(is_deleted: 0)

          # FIXME(ezekg) should we move this into a separate counter?
          if resource_type.present? && resource_id.present?
            scope = scope.where(
              resource_type: resource_type.classify,
              resource_id:,
            )
          end

          scope.group(:event_type_id)
               .count
        end
      end
    end
  end
end
