# frozen_string_literal: true

module Analytics
  class StatNotFoundError < StandardError; end

  module Stat
    def self.call(type, account:, environment: nil)
      klass = case type.to_s.underscore.to_sym
              in :machines then Machines
              in :users then Users
              in :licenses then Licenses
              in :alus then ActiveLicensedUsers
              else nil
              end

      raise StatNotFoundError, "invalid stat type: #{type.inspect}" if klass.nil?

      klass.new(account:, environment:).result
    end
  end
end
