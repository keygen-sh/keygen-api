# frozen_string_literal: true

module Analytics
  class Count
    module Counters
      class ActiveLicensedUsers
        def initialize(account:, **) # environment intentionally ignored
          @account = account
        end

        def count
          account.active_licensed_user_count
        end

        private

        attr_reader :account
      end
    end
  end
end
