# frozen_string_literal: true

module Analytics
  class SeriesNotFoundError < StandardError; end

  class Series
    COUNTERS = {
      events: Counters::Events,
      requests: Counters::Requests,
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
      counter.validate(errors)
    end

    def initialize(counter_name, **options)
      @counter_name = counter_name.to_s.underscore.to_sym

      raise SeriesNotFoundError, "invalid series: #{@counter_name.inspect}" unless
        COUNTERS.key?(@counter_name)

      @counter_options = options.except(:account, :environment, :start_date, :end_date)

      super(**options.slice(:account, :environment, :start_date, :end_date))
    end

    def buckets = @buckets ||= begin
      counts = counter.count(start_date:, end_date:)

      counter.groups.flat_map do |group|
        (start_date..end_date).map do |date|
          count = counts[counter.count_key(group:, date:)].to_i

          counter.bucket(group:, date:, count:)
        end
      end
    end

    delegate :as_json, :to_json,
      to: :buckets

    def cache_key
      digest = Digest::SHA2.hexdigest("#{counter_name}:#{counter.cache_key}:#{start_date}:#{end_date}")

      "analytics:series:#{account.id}:#{environment&.id}:#{digest}:#{CACHE_KEY_VERSION}"
    end

    private

    attr_reader :counter_name

    def counter_class = COUNTERS[counter_name]
    def counter       = @counter ||= counter_class.new(account:, environment:, **@counter_options)
  end
end
