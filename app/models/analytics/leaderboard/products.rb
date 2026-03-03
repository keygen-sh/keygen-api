# frozen_string_literal: true

module Analytics
  class Leaderboard
    class Products
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def count(start_date:, end_date:, limit:)
        ReleaseDownloadSpark.for_account(account)
                            .for_environment(environment)
                            .where(created_date: start_date..end_date)
                            .group(:product_id)
                            .order(Arel.sql('sum_count DESC'))
                            .limit(limit)
                            .sum(:count)
      end

      private

      attr_reader :account, :environment
    end
  end
end
