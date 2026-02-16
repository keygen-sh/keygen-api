# frozen_string_literal: true

module Analytics
  class Stat
    module Counters
      module Machines
        def self.count(account:, environment:)
          account.machines.for_environment(environment).count
        end
      end
    end
  end
end
