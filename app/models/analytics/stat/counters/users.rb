# frozen_string_literal: true

module Analytics
  class Stat
    module Counters
      class Users
        def initialize(account:, environment:)
          @account     = account
          @environment = environment
        end

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
end
