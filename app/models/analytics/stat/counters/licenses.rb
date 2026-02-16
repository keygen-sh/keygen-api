# frozen_string_literal: true

module Analytics
  class Stat
    module Counters
      module Licenses
        def self.count(account:, environment:)
          account.licenses.for_environment(environment).count
        end
      end
    end
  end
end
