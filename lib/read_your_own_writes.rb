# frozen_string_literal: true

require 'active_support'
require 'active_record'

module ReadYourOwnWrites
  SKIP_RYOW_KEY    = 'database.skip_ryow'
  REDIS_KEY_PREFIX = 'ryow'

  # Immutable struct representing the identity of a client for RYOW tracking.
  # Used to generate a unique fingerprint for storing write timestamps.
  Client = Data.define :id do
    def to_s = "client:#{Digest::SHA2.hexdigest(id.to_s)}"
  end

  class Configuration
    # How long after a write to route reads to primary. Synced automatically from
    # config.active_record.database_selector[:delay] after Rails initializes.
    attr_reader :database_selector_delay

    # Redis key prefix for storing write timestamps.
    attr_accessor :redis_key_prefix

    # Time-to-live for write timestamp entries in Redis.
    # Defaults to database_selector_delay * 2.
    attr_writer :redis_ttl

    # Path patterns that should always read from replica, regardless of recent
    # writes. Useful for read-only POST endpoints like search or validation.
    attr_accessor :ignored_request_paths

    # Proc to extract client identity from request for fingerprinting.
    # Must return a Client struct. Default uses authorization header and remote IP.
    #
    # NB(ezekg) This is run BEFORE the Rails app via Rails' DatabaseSelector
    #           middleware, so things like route params are NOT available.
    attr_accessor :client_identifier

    def initialize
      @database_selector_delay = 2.seconds
      @redis_key_prefix        = REDIS_KEY_PREFIX
      @redis_ttl               = nil
      @ignored_request_paths   = []
      @client_identifier       = ->(request) {
        id = [request.authorization, request.remote_ip].join(':')

        Client.new(id:)
      }
    end

    def redis_ttl = @redis_ttl || @database_selector_delay * 2

    private

    def database_selector_delay=(delay)
      database_selector_delay = delay
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Reset configuration to defaults (useful for testing)
    def reset_configuration!
      @configuration = Configuration.new
    end

    # Check if the request is reading its own recent writes.
    def reading_own_writes?(request)
      context = Resolver::Context.new(request)
      last_write = context.last_write_timestamp

      Time.current - last_write < configuration.database_selector_delay
    end
  end

  module Controller
    extend ActiveSupport::Concern

    class_methods do
      # use_primary always connects to the primary database (useful for GET requests that perform writes)
      def use_primary(**) = prepend_around_action(:with_primary_connection, **)

      # use_read_replica connects to the replica database unless there has been a recent write (mainly
      # useful for readonly POST requests, e.g. license validation and search)
      def use_read_replica(always: true, **)
        prepend_around_action(always ? :with_read_replica_connection : :with_read_replica_connection_unless_reading_own_writes, **)
      end

      # prefer_read_replica respects ryow behavior (i.e. prefer replica unless recent write)
      def prefer_read_replica(**) = use_read_replica(**, always: false)
    end

    def with_primary_connection
      ActiveRecord::Base.connected_to(role: :writing) { yield }
    end

    def with_read_replica_connection_unless_reading_own_writes
      if ReadYourOwnWrites.reading_own_writes?(request)
        yield # noop since already handled elsewhere
      else
        ActiveRecord::Base.connected_to(role: :reading) { yield }
      end
    end

    def with_read_replica_connection
      ActiveRecord::Base.connected_to(role: :reading) { yield }
    end
  end

  # Custom resolver that inherits from Rails' DatabaseSelector::Resolver.
  # This allows us to customize behavior in the future if needed.
  class Resolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
    # Redis-based resolver context for read-your-own-writes in API-only apps.
    #
    # Unlike the default Session resolver which uses cookies, this resolver
    # stores write timestamps in Redis. Any write causes all subsequent reads
    # to use primary for the configured delay period.
    #
    # @example Force replica in controller
    #   request.env[ReadYourOwnWrites::SKIP_RYOW_KEY] = true
    #
    class Context
      class << self
        def call(request) = new(request)

        def convert_time_to_timestamp(t)
          t.to_i * 1000 + t.usec / 1000
        end

        def convert_timestamp_to_time(t)
          t ? Time.at(t / 1000, (t % 1000) * 1000) : Time.at(0)
        end
      end

      attr_reader :request

      def initialize(request)
        @request = request
        @config = ReadYourOwnWrites.configuration
      end

      def last_write_timestamp
        return Time.at(0) if replica_only_request?

        timestamp = redis { it.get(redis_key) }

        return Time.at(0) if timestamp.nil?

        self.class.convert_timestamp_to_time(timestamp.to_i)
      end

      def update_last_write_timestamp
        t = self.class.convert_time_to_timestamp(Time.now)

        redis { it.setex(redis_key, @config.redis_ttl, t) }
      end

      def save(response)
        # No-op: state is stored in Redis, not the response
      end

      private

      def redis_key = "#{@config.redis_key_prefix}:#{client_id}"

      def redis(&)
        Rails.cache.redis.then(&)
      rescue Redis::BaseError, Errno::ECONNREFUSED
        # If Redis is unavailable, fail open (allow reads from replica)
        nil
      end

      def client_id
        @client_id ||= begin
          identity = @config.client_identifier.call(request)

          raise TypeError, "client_identifier must return a Client, got #{identity.class}" unless identity.is_a?(Client)

          identity.to_s
        end
      end

      def replica_only_request?
        return true if request.env[SKIP_RYOW_KEY]

        path = request.path.split('?').first.chomp('/')

        @config.ignored_request_paths.any? { it.match?(path) }
      end
    end
  end

  # using after_initialize instead of on_load(:active_record) to make sure we pick up any
  # changes to the database selector delay inside of initializers, e.g. multi_db.rb.
  Rails.application.config.after_initialize do
    if (selector = Rails.application.config.active_record.database_selector)
      ReadYourOwnWrites.configuration.send(:database_selector_delay=, selector[:delay])
    end
  end
end
