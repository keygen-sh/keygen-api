# frozen_string_literal: true

module Analytics
  class Activity
    module Counters
      module EventTypes
        def self.count(account:, environment:, event_type_ids:, start_date:, end_date:)
          EventLog::Clickhouse.where(account_id: account.id)
                              .where(environment_id: environment&.id)
                              .where(created_date: start_date..end_date)
                              .where(event_type_id: event_type_ids)
                              .where(is_deleted: 0)
                              .group(:event_type_id)
                              .count
        end
      end
    end
  end
end
