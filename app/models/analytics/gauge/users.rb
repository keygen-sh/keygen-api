# frozen_string_literal: true

module Analytics
  class Gauge
    class Users
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def metrics = %w[users]
      def count
        count  = account.users.for_environment(environment).with_roles(:user).count
        metric = metrics.sole

        { metric => count }
      end

      private

      attr_reader :account, :environment
    end
  end
end
