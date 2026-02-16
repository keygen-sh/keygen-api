# frozen_string_literal: true

module Analytics
  class Stat
    module Counters
      module Users
        def self.count(account:, environment:)
          account.users.for_environment(environment)
                       .with_roles(:user)
                       .count
        end
      end
    end
  end
end
