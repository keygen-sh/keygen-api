# frozen_string_literal: true

module Analytics
  class Gauge
    class Machines
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def metrics = %w[machines]
      def count
        account.machines.for_environment(environment).count
      end

      private

      attr_reader :account, :environment
    end
  end
end
