# frozen_string_literal: true

module Analytics
  class GaugeNotFoundError < StandardError; end

  class Gauge
    include ActiveModel::Model
    include ActiveModel::Attributes

    COUNTERS = {
      active_licensed_users: ActiveLicensedUsers,
      machines: Machines,
      licenses: Licenses,
      users: Users,
      alus: ActiveLicensedUsers, # alias
    }

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    validates :account, presence: true

    def initialize(counter_name, **)
      @counter_name = counter_name = counter_name.to_s.underscore.to_sym

      raise GaugeNotFoundError, "invalid gauge: #{counter_name.inspect}" unless
        COUNTERS.key?(counter_name)

      super(**)
    end

    def count
      @count ||= counter.count
    end

    def as_json(*) = { count: }

    def cache_key
      digest = Digest::SHA2.hexdigest("#{counter_name}")

      "analytics:gauges:#{account.id}:#{environment&.id}:#{digest}:#{CACHE_KEY_VERSION}"
    end

    private

    attr_reader :counter_name

    def counter_class = COUNTERS[counter_name]
    def counter       = @counter ||= counter_class.new(account:, environment:)
  end
end
