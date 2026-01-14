# frozen_string_literal: true

require 'active_support'
require 'active_record'

module ReadYourOwnWrites
  RYOW_SKIP_KEY    = 'database.skip_ryow'
  REDIS_KEY_PREFIX = 'ryow'

  # immutable struct representing the unique identity of a client
  Client = Data.define :fingerprint do
    def to_s = "client:#{Digest::SHA2.hexdigest(fingerprint.to_s)}"
  end

  class Configuration
    # how long after a write to route reads to primary
    attr_reader :database_selector_delay

    # redis key prefix for storing write timestamps
    attr_accessor :redis_key_prefix

    # time-to-live for write timestamp entries in Redis
    #
    # defaults to database_selector_delay * 2
    attr_writer :redis_ttl

    # path patterns that should always read from replica regardless of recent writes
    #
    # this is useful for read-only POST endpoints like search
    attr_accessor :ignored_request_paths

    # client_identifier should be a proc that returns a Client
    #
    # defaults to Authorization header and remote IP
    #
    # NB(ezekg) this is run BEFORE the Rails app via Rails' DatabaseSelector
    #           middleware i.e. things like route params are NOT available
    attr_accessor :client_identifier

    def initialize
      @database_selector_delay = 2.seconds
      @redis_key_prefix        = REDIS_KEY_PREFIX
      @redis_ttl               = nil
      @ignored_request_paths   = []
      @client_identifier       = ->(request) {
        fingerprint = [request.authorization, request.remote_ip].join(':')

        Client.new(fingerprint:)
      }
    end

    def redis_ttl = @redis_ttl || @database_selector_delay * 2

    private

    def database_selector_delay=(delay)
      database_selector_delay = delay
    end
  end

  class << self
    def configuration = @configuration ||= Configuration.new
    def configuration=(config)
      @configuration = config
    end

    def configure
      yield configuration
    end

    # check if the request is reading its own recent writes
    def reading_own_writes?(request)
      context       = Resolver::Context.new(request)
      last_write_at = context.last_write_timestamp

      Time.current - last_write_at < configuration.database_selector_delay
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
        yield # noop since already handled by database selector middleware
      else
        ActiveRecord::Base.connected_to(role: :reading) { yield }
      end
    end

    def with_read_replica_connection
      ActiveRecord::Base.connected_to(role: :reading) { yield }
    end
  end

  class Resolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
    def reading_request?(request) = super || context.ignored?
    def update_context(response)  = nil # noop

    class Context
      EPOCH = Time.at(0)

      attr_reader :request,
                  :config

      # NB(ezekg) this odd service-object-but-not-really call pattern is required
      #           by the database selector middleware
      def self.call(request) = new(request)

      def initialize(request)
        @request = request
        @config  = ReadYourOwnWrites.configuration
      end

      def last_write_timestamp
        return EPOCH if ignored?

        value = redis { it.get(redis_key) }
        return EPOCH if value.nil?

        Time.at(value.to_i)
      end

      def update_last_write_timestamp
        return if ignored?

        value = Time.current.to_i

        redis { it.setex(redis_key, config.redis_ttl, value) }
      end

      def ignored?
        return true if request.env[RYOW_SKIP_KEY]

        config.ignored_request_paths.any? { it.match?(request.path) }
      end

      private

      def redis_key = "#{@config.redis_key_prefix}:#{client_id}"
      def redis(&)
        Rails.cache.redis.then(&)
      rescue Redis::BaseError, Errno::ECONNREFUSED
        nil # fail open if redis is unreachable
      end

      def client_id
        @client_id ||= begin
          client = @config.client_identifier.call(request)

          raise TypeError, "client_identifier must return a Client, got #{client.class}" unless
            client in Client

          client.to_s
        end
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
