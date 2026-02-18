# frozen_string_literal: true

module Analytics
  class Activity
    module Counters
      class EventTypes
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count(event_type_ids:, start_date:, end_date:, resource_type: nil, resource_id: nil)
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

          scope.group(:event_type_id)
               .count
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
