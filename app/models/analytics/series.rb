# frozen_string_literal: true

module Analytics
  class SeriesNotFoundError < StandardError; end

  class Series
    Bucket = Data.define(:metric, :date, :count)

    COUNTERS = {
      events: Events,
      requests: Requests,
      sparks: Sparks,
      validations: Validations,
    }

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    attribute :start_date, default: -> { 2.weeks.ago.to_date }
    attribute :end_date, default: -> { Date.current }

    validates :account, presence: true
    validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.year.ago.to_date } }
    validates :end_date, comparison: { less_than_or_equal_to: -> { Date.current } }

    validate do
      errors.add :metrics, 'is invalid' if metrics.empty?
    end

    def initialize(metric, **options)
      @counter_name = metric = metric.to_s.underscore.to_sym

      raise SeriesNotFoundError, "invalid metric: #{metric.inspect}" unless
        COUNTERS.key?(metric)

      # split ours vs theirs (doing it this way to keep optionals w/ defaults sane)
      options, @counter_options = options.split(
        :account,
        :environment,
        :start_date,
        :end_date,
      )

      super(**options)
    end

    def metrics = @metrics ||= counter.metrics
    def buckets = @buckets ||= begin
      counts = counter.count(start_date:, end_date:)

      metrics.flat_map do |metric|
        (start_date..end_date).filter_map do |date|
          count = counts[[metric, date]].to_i
          next if count.zero?

          Bucket.new(metric:, date:, count:)
        end
      end
    end

    delegate :as_json, :to_json,
      to: :buckets

    def cache_key
      digest = Digest::SHA2.hexdigest("#{counter_name}:#{counter_options.sort.as_json}:#{start_date}:#{end_date}")

      "analytics:series:#{account.id}:#{environment&.id}:#{digest}:#{CACHE_KEY_VERSION}"
    end

    private

    attr_reader :counter_name,
                :counter_options

    def counter_class = COUNTERS[counter_name]
    def counter       = @counter ||= counter_class.new(account:, environment:, **counter_options)
  end
end
