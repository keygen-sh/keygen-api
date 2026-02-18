# frozen_string_literal: true

module Analytics
  class Usage
    module Counters
      class Requests
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count(start_date:, end_date:)
          scope = RequestLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                        .where(created_date: start_date..end_date, is_deleted: 0)
                                        .order(:created_date)

          scope.group(:created_date)
               .count
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
