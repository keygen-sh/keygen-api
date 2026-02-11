# frozen_string_literal: true

module Analytics
  class UsersCountQuery < BaseQuery
    def initialize(account:, environment: nil)
      @account     = account
      @environment = environment
    end

    def call
      count = account.users.for_environment(environment)
                           .with_roles(:user)
                           .count

      Stat::Count.new(count:)
    end

    private

    attr_reader :account,
                :environment
  end
end
