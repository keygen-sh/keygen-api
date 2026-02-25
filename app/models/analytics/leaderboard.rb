# frozen_string_literal: true

module Analytics
  class LeaderboardNotFoundError < StandardError; end

  class Leaderboard
    Score = Data.define(:discriminator, :count)

    include ActiveModel::Model
    include ActiveModel::Attributes

    MAX_LIMIT = 100
    COUNTERS  = {
      user_agents: UserAgents,
      licenses: Licenses,
      urls: Urls,
      ips: Ips,
    }

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    attribute :start_date, default: -> { 2.weeks.ago.to_date }
    attribute :end_date, default: -> { Date.current }
    attribute :limit, default: -> { 10 }

    validates :account, presence: true
    validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.year.ago.to_date } }
    validates :end_date, comparison: { less_than_or_equal_to: -> { Date.current } }
    validates :limit, numericality: { less_than_or_equal_to: MAX_LIMIT }

    def initialize(metric, **)
      @counter_name = metric = metric.to_s.underscore.to_sym

      raise LeaderboardNotFoundError, "invalid metric: #{metric.inspect}" unless
        COUNTERS.key?(metric)

      super(**)
    end

    def scores = @scores ||= begin
      counts = counter.count(start_date:, end_date:, limit:)

      counts.map do |(discriminator, count)|
        Score.new(discriminator:, count:)
      end
    end

    delegate :as_json, :to_json,
      to: :scores

    def cache_key
      digest = Digest::SHA2.hexdigest("#{counter_name}:#{start_date}:#{end_date}:#{limit}")

      "analytics:leaderboards:#{account.id}:#{environment&.id}:#{digest}:#{CACHE_KEY_VERSION}"
    end

    private

    attr_reader :counter_name

    def counter_class = COUNTERS[counter_name]
    def counter       = @counter ||= counter_class.new(account:, environment:)
  end
end
