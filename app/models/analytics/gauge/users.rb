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
        account.users.for_environment(environment)
                     .with_roles(:user)
                     .count
      end

      private

      attr_reader :account, :environment
    end
  end
end
