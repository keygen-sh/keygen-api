# frozen_string_literal: true

module Analytics
  class Stat
    module Counters
      module ActiveLicensedUsers
        def self.count(account:, environment:) # environment intentionally ignored
          account.active_licensed_user_count
        end
      end
    end
  end
end
