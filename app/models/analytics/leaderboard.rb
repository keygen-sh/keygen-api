# frozen_string_literal: true

module Analytics
  class LeaderboardNotFoundError < StandardError; end

  module Leaderboard
    def self.call(type, account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current, limit: 10)
      klass = case type.to_s.underscore.to_sym
              in :ips then Ips
              in :urls then Urls
              in :licenses then Licenses
              in :user_agents then UserAgents
              else nil
              end

      raise LeaderboardNotFoundError, "invalid leaderboard type: #{type.inspect}" if klass.nil?

      klass.new(account:, environment:, start_date:, end_date:, limit:).result
    end
  end
end
