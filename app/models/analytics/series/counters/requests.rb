# frozen_string_literal: true

module Analytics
  class Series
    module Counters
      class Requests
        Bucket = Data.define(:date, :count)

        def initialize(account:, environment:, **)
          @account     = account
          @environment = environment
        end

        def groups = [nil]

        def count(start_date:, end_date:)
          RequestLog::Clickhouse.where(account_id: account.id, environment_id: environment&.id)
                                .where(created_date: start_date..end_date, is_deleted: 0)
                                .order(:created_date)
                                .group(:created_date)
                                .count
        end

        def count_key(group:, date:) = date
        def bucket(group:, date:, count:) = Bucket.new(date:, count:)

        def cache_key = ''
        def validate(errors) = nil

        private

        attr_reader :account, :environment
      end
    end
  end
end
