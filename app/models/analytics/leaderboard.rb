# frozen_string_literal: true

module Analytics
  class LeaderboardNotFoundError < StandardError; end

  module Leaderboard
    extend self

    def call(leaderboard_id, account:, environment: nil, start_date: 2.weeks.ago.to_date, end_date: Date.current, limit: 10)
      leaderboard = case to_ident(leaderboard_id)
                    in :ips then IpsLeaderboardQuery
                    in :urls then UrlsLeaderboardQuery
                    in :licenses then LicensesLeaderboardQuery
                    in :user_agents then UserAgentsLeaderboardQuery
                    else nil
                    end

      raise LeaderboardNotFoundError, "invalid leaderboard identifier: #{leaderboard_id.inspect}" unless
        leaderboard.present?

      leaderboard.call(account:, environment:, start_date:, end_date:, limit:)
    end

    private

    def to_ident(id) = id.to_s.underscore.to_sym
  end
end
