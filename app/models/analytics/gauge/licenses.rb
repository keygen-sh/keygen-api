# frozen_string_literal: true

module Analytics
  class Gauge
    class Licenses
      def initialize(account:, environment:)
        @account     = account
        @environment = environment
      end

      def count
        account.licenses.for_environment(environment).count
      end

      private

      attr_reader :account, :environment
    end
  end
end
