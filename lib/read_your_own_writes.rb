# frozen_string_literal: true

require 'active_support'
require 'active_record'

module ReadYourOwnWrites
  SKIP_RYOW_KEY    = 'database.skip_ryow'
  REDIS_KEY_PREFIX = 'ryow'

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

    # Proc to extract client identifier parts from request for fingerprinting.
    # Default uses authorization header and remote IP.
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
        [request.authorization, request.remote_ip]
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
      context = RedisContext.new(request)
      last_write = context.last_write_timestamp

      Time.current - last_write < configuration.database_selector_delay
    end
  end

  module Controller
    extend ActiveSupport::Concern

    class_methods do
      # use_read_replica connects to the replica database unless there has been a recent write (mainly
      # useful for readonly POST requests, e.g. license validation and search)
      def use_read_replica(always: true, **)
        prepend_around_action(always ? :with_read_replica_connection : :with_read_replica_connection_unless_reading_own_writes, **)
      end

      # prefer_read_replica respects ryow behavior (i.e. prefer replica unless recent write)
      def prefer_read_replica(**) = use_read_replica(**, always: false)
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

  # Redis-based resolver context for read-your-own-writes in API-only apps.
  #
  # Unlike the default Session resolver which uses cookies, this resolver
  # stores write timestamps in Redis using path-based prefix matching.
  # This ensures reads are routed to primary only when they might be
  # affected by a recent write from the same client.
  #
  # Path matching rules:
  # - A write to /accounts/foo/licenses/bar affects:
  #   - GET /accounts/foo/licenses (parent path - listing might include the written resource)
  #   - GET /accounts/foo/licenses/bar/actions/validate (child path - operates on written resource)
  # - But does NOT affect:
  #   - GET /accounts/foo/users (sibling path - different resource type)
  #
  # @example Configuration
  #   # config/initializers/read_your_own_writes.rb
  #   ReadYourOwnWrites.configure do |config|
  #     config.ignored_request_paths = [
  #       /\/actions\/validate-key\z/,
  #       /\/actions\/search\z/,
  #     ]
  #   end
  #
  #   # config/initializers/multi_db.rb
  #   config.active_record.database_resolver_context = ReadYourOwnWrites::RedisContext
  #
  # @example Force replica in controller
  #   request.env[ReadYourOwnWrites::SKIP_RYOW_KEY] = true
  #
  class RedisContext
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
      # Replica-only requests always return epoch (use replica)
      return Time.at(0) if replica_only_request?

      # Get all recent writes for this client
      writes = redis { it.zrangebyscore(redis_key, '-inf', '+inf', with_scores: true) }

      return Time.at(0) if writes.nil? || writes.empty?

      # Find the most recent write that matches our path
      matching_timestamp = writes
        .select { |path, _| path_matches?(path, request_path) }
        .map { |_, score| score.to_i }
        .max

      self.class.convert_timestamp_to_time(matching_timestamp)
    end

    def update_last_write_timestamp
      t = self.class.convert_time_to_timestamp(Time.now)
      cutoff = t - (@config.redis_ttl.to_i * 1000)

      redis do |r|
        r.multi do |tx|
          # Add this write path with its timestamp
          tx.zadd(redis_key, t, request_path)
          # Remove expired entries
          tx.zremrangebyscore(redis_key, '-inf', cutoff)
          # Set TTL on the whole key
          tx.expire(redis_key, @config.redis_ttl)
        end
      end
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
        identifiers = @config.client_identifier.call(request)

        Digest::SHA2.hexdigest(Array(identifiers).join(':'))
      end
    end

    def request_path
      # Normalize path: remove trailing slash, remove query string
      @request_path ||= request.path.chomp('/').split('?').first
    end

    def replica_only_request?
      # Check request env override
      return true if request.env[SKIP_RYOW_KEY]

      # Check configured patterns
      @config.ignored_request_paths.any? { it.match?(request_path) }
    end

    def path_matches?(write_path, read_path)
      # Paths match if one is a prefix of the other (delimited by /)
      # This handles both cases:
      # - Read is parent of write: GET /licenses matches write to /licenses/bar
      # - Read is child of write: GET /licenses/bar/validate matches write to /licenses/bar
      write_segments = write_path.split('/')
      read_segments = read_path.split('/')

      # Check if write path is prefix of read path
      return true if segments_prefix?(write_segments, read_segments)

      # Check if read path is prefix of write path
      return true if segments_prefix?(read_segments, write_segments)

      false
    end

    def segments_prefix?(prefix_segments, full_segments)
      return false if prefix_segments.length > full_segments.length

      prefix_segments.each_with_index.all? { |segment, i| segment == full_segments[i] }
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
