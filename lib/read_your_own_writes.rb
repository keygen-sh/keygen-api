# frozen_string_literal: true

require 'active_support'
require 'active_record'

module ReadYourOwnWrites
  SKIP_RYOW_KEY    = 'database.skip_ryow'
  REDIS_KEY_PREFIX = 'ryow'

  # Immutable struct representing the identity of a client for RYOW tracking.
  # Used to generate a unique fingerprint for storing write timestamps.
  ClientIdentity = Data.define :id do
    def to_s = "client:#{Digest::SHA2.hexdigest(id.to_s)}"
  end

  # Immutable struct representing the resolved request path for RYOW tracking.
  # The segments array contains path scopes, from most general to most specific.
  # Path matching checks if two segments arrays share a common prefix.
  #
  # @example RESTful resource segments
  #   # For /v1/accounts/abc/licenses/xyz:
  #   RequestPath.new(segments: ['/v1/accounts/abc', '/v1/accounts/abc/licenses', '/v1/accounts/abc/licenses/xyz'])
  #
  # @example Opting out of path filtering (all requests match)
  #   RequestPath.new(segments: nil)
  #
  RequestPath = Data.define :segments do
    def matches?(other)
      # nil segments matches everything (opt-out of path filtering)
      return true if segments.nil? || other.segments.nil?

      # Check if any scope in one segments array is a prefix of any scope in the other
      segments.product(other.segments).any? do |s1, s2|
        prefix?(s1, s2) || prefix?(s2, s1)
      end
    end

    def to_s = segments&.last || '/'

    private

    def prefix?(a, b)
      b.start_with?(a) && (a == b || b[a.length] == '/')
    end
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
    # Must return a ClientIdentity struct. Default uses authorization header and remote IP.
    #
    # NB(ezekg) This is run BEFORE the Rails app via Rails' DatabaseSelector
    #           middleware, so things like route params are NOT available.
    attr_accessor :client_identifier

    # Proc to resolve request path for RYOW tracking.
    # Must return a RequestPath struct. Default returns nil segments (all requests match).
    # Configure a custom resolver to opt into path-based matching.
    #
    # NB(ezekg) This is run BEFORE the Rails app via Rails' DatabaseSelector
    #           middleware, so things like route params are NOT available.
    attr_accessor :request_path_resolver

    def initialize
      @database_selector_delay = 2.seconds
      @redis_key_prefix        = REDIS_KEY_PREFIX
      @redis_ttl               = nil
      @ignored_request_paths   = []
      @client_identifier       = ->(request) {
        id = [request.authorization, request.remote_ip].join(':')

        ClientIdentity.new(id:)
      }
      @request_path_resolver   = ->(request) {
        RequestPath.new(segments: nil)
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
    # stores write timestamps in Redis. By default, any write causes all
    # subsequent reads to use primary for the configured delay period.
    #
    # Path-based matching can be enabled via the request_path_resolver config
    # to scope RYOW to specific resource paths.
    #
    # @example Opting into path-based matching (prefix matching)
    #   ReadYourOwnWrites.configure do |config|
    #     config.request_path_resolver = ->(request) {
    #       path = request.path.chomp('/').split('?').first
    #       ReadYourOwnWrites::RequestPath.new(segments: [path])
    #     }
    #   end
    #
    # @example RESTful resource-based path resolution
    #   ReadYourOwnWrites.configure do |config|
    #     config.request_path_resolver = ->(request) {
    #       # Build segments of resource scopes from the URL path
    #       parts = request.path.split('/').reject(&:blank?)
    #       segments = parts.each_slice(2).each_with_object([]) { |pair, acc|
    #         acc << [acc.last, pair.join('/')].compact.join('/')
    #       }
    #       ReadYourOwnWrites::RequestPath.new(segments:)
    #     }
    #   end
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
        # Replica-only requests always return epoch (use replica)
        return Time.at(0) if replica_only_request?

        # Get all recent writes for this client
        writes = redis { it.zrangebyscore(redis_key, '-inf', '+inf', with_scores: true) }

        return Time.at(0) if writes.nil? || writes.empty?

        # Build a RequestPath from stored write scopes for comparison
        write_scopes = writes.map { |scope, _| scope }
        write_path   = RequestPath.new(segments: write_scopes)

        pp(write_path:, request_path:)

        # Check if any write scope matches current request
        return Time.at(0) unless request_path.matches?(write_path)

        # Return the most recent matching timestamp
        matching_timestamp = writes.map { |_, score| score.to_i }.max

        self.class.convert_timestamp_to_time(matching_timestamp)
      end

      def update_last_write_timestamp
        t = self.class.convert_time_to_timestamp(Time.now)
        cutoff = t - (@config.redis_ttl.to_i * 1000)
        scopes = request_path.segments || ['/']

        redis do |r|
          r.multi do |tx|
            # Add each scope in the path segments with the same timestamp
            scopes.each { |scope| tx.zadd(redis_key, t, scope) }
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
          identity = @config.client_identifier.call(request)

          raise TypeError, "client_identifier must return a ClientIdentity, got #{identity.class}" unless identity.is_a?(ClientIdentity)

          identity.to_s
        end
      end

      def request_path
        @request_path ||= begin
          path = @config.request_path_resolver.call(request)

          raise TypeError, "request_path_resolver must return a RequestPath, got #{path.class}" unless path.is_a?(RequestPath)

          path
        end
      end

      def replica_only_request?
        # Check request env override
        return true if request.env[SKIP_RYOW_KEY]

        # Check configured patterns
        @config.ignored_request_paths.any? { it.match?(request_path.to_s) }
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
