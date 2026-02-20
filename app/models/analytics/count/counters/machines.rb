# frozen_string_literal: true

module Analytics
  class Count
    module Counters
      class Machines
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

        def count
          account.machines.for_environment(environment).count
        end

        private

        attr_reader :account, :environment
      end
    end
  end
end
