# frozen_string_literal: true

module Analytics
  class StatNotFoundError < StandardError; end

  module Stat
    extend self

    def call(stat_id, account:, environment: nil)
      stat = case to_ident(stat_id)
             in :machines then MachinesCountQuery
             in :users then UsersCountQuery
             in :licenses then LicensesCountQuery
             in :alus then ActiveLicensedUsersCountQuery
             else nil
             end

      raise StatNotFoundError, "invalid stat identifier: #{stat_id.inspect}" unless
        stat.present?

      stat.call(account:, environment:)
    end

    private

    def to_ident(id) = id.to_s.underscore.to_sym
  end
end
