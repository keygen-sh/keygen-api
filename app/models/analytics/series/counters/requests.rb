# frozen_string_literal: true

module Analytics
  class Series
    module Counters
      class Requests
        def initialize(account:, environment:, **)
          @account     = account
          @environment = environment
        end

        METRIC = 'usage'

        def metrics = [METRIC]

        def count(start_date:, end_date:)
          counts = RequestLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                         .where(created_date: start_date..end_date, is_deleted: 0)
                                         .order(:created_date)
                                         .group(:created_date)
                                         .count

          counts.transform_keys { [METRIC, _1] }
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
