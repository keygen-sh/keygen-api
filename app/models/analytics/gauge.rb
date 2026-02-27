# frozen_string_literal: true

module Analytics
  class GaugeNotFoundError < StandardError; end

  class Gauge
    include ActiveModel::Model
    include ActiveModel::Attributes

    COUNTERS = {
      alus: ActiveLicensedUsers,
      licenses: Licenses,
      machines: Machines,
      users: Users,
      validations: Validations,
    }

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    validates :account, presence: true

    def initialize(metric, **options)
      @counter_name = metric = metric.to_s.underscore.to_sym

      raise GaugeNotFoundError, "invalid metric: #{metric.inspect}" unless
        COUNTERS.key?(metric)

      # split ours vs theirs
      options, @counter_options = options.split(
        :account,
        :environment,
      )

      super(**options)
    end

    def metrics = @metrics ||= counter.metrics
    def count
      @count ||= counter.count
    end

    def as_json(*)
      if metrics.many?
        counts = count

        metrics.filter_map do |metric|
          count = counts[metric]
          next if
            count.nil?

          { metric:, count: }
        end
      else
        metrics.map {{ metric: it, count: }}
      end
    end

    def cache_key
      digest = Digest::SHA2.hexdigest("#{counter_name}")

      "analytics:gauges:#{account.id}:#{environment&.id}:#{digest}:#{CACHE_KEY_VERSION}"
    end

    private

    attr_reader :counter_name,
                :counter_options

    def counter_class = COUNTERS[counter_name]
    def counter       = @counter ||= counter_class.new(account:, environment:, **counter_options)
  end
end
