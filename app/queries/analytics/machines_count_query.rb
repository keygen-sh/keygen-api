# frozen_string_literal: true

module Analytics
  class MachinesCountQuery < BaseQuery
    Result = Data.define(:count)

    def initialize(account:, environment: nil)
      @account     = account
      @environment = environment
    end

    def call
      count = account.machines.for_environment(environment)
                              .count

      Result.new(count:)
    end

    private

    attr_reader :account,
                :environment
  end
end
