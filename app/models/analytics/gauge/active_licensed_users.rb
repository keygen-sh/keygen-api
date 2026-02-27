# frozen_string_literal: true

module Analytics
  class Gauge
    class ActiveLicensedUsers
      def initialize(account:, **) # environment intentionally ignored
        @account = account
      end

      def metrics = %w[alus]
      def count
        count  = account.active_licensed_user_count
        metric = metrics.sole

        { metric => count }
      end

      private

      attr_reader :account
    end
  end
end
