# frozen_string_literal: true

module Analytics
  class ActiveLicensedUsersCountQuery < BaseQuery
    def initialize(account:, environment: nil)
      # NB(ezekg) environment is intentionally ignored
      @account = account
    end

    def call
      count = account.active_licensed_user_count

      Stat::Count.new(count:)
    end

    private

    attr_reader :account
  end
end
