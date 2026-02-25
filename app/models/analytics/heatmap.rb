# frozen_string_literal: true

module Analytics
  class HeatmapNotFoundError < StandardError; end

  class Heatmap
    Cell = Data.define(:date, :x, :y, :temperature, :count)

    include ActiveModel::Model
    include ActiveModel::Attributes

    COUNTERS = {
      expirations: Expirations,
    }

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    attribute :start_date, default: -> { Date.current }
    attribute :end_date, default: -> { 364.days.from_now.to_date }

    validates :account, presence: true
    validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.month.ago.to_date } }
    validates :end_date, comparison: { less_than_or_equal_to: -> { 1.year.from_now.to_date } }

    def initialize(metric, **)
      @counter_name = metric = metric.to_s.underscore.to_sym

      raise HeatmapNotFoundError, "invalid metric: #{metric.inspect}" unless
        COUNTERS.key?(metric)

      super(**)
    end

    def cells = @cells ||= begin
      grid_start = start_date.beginning_of_week(:sunday)
      counts     = counter.count(start_date:, end_date:)
      max_count  = counts.values.max || 1

      (start_date..end_date).filter_map do |date|
        count = counts[date].to_i
        next if count.zero?

        offset = (date - grid_start).to_i
        temp   = (count.to_f / max_count).round(1)

        Cell.new(
          x: offset / 7,
          y: date.wday,
          temperature: temp,
          count:,
          date:,
        )
      end
    end

    # these are internal models so we aren't going to use serializers rn
    delegate :as_json, :to_json,
      to: :cells

    def cache_key
      digest = Digest::SHA2.hexdigest("#{counter_name}:#{start_date}:#{end_date}")

      "analytics:heatmaps:#{account.id}:#{environment&.id}:#{digest}:#{CACHE_KEY_VERSION}"
    end

    private

    attr_reader :counter_name

    def counter_class = COUNTERS[counter_name]
    def counter       = @counter ||= counter_class.new(account:, environment:)
  end
end
