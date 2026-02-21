# frozen_string_literal: true

module Analytics
  class Heatmap
    class Expirations
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def count(start_date:, end_date:)
        account.licenses.unordered
                        .for_environment(environment)
                        .where.not(expiry: nil)
                        .where(expiry: start_date.beginning_of_day..end_date.end_of_day)
                        .group(Arel.sql('DATE(expiry)'))
                        .count
      end

      private

      attr_reader :account, :environment
    end
  end
end
