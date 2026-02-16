# frozen_string_literal: true

module Analytics
  module Event
    extend self

    def call(pattern, account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current)
      EventCountQuery.call(account:, environment:, event: pattern, start_date:, end_date:)
    end
  end
end
