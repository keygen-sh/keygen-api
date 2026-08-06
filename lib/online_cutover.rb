# frozen_string_literal: true

require 'active_support'
require 'active_record'
require 'singleton'
require 'json'

# coordinates zero-downtime database cutover across web and worker processes for a promoted replica
#
# == Cutover procedure
#
#   1. run `rake online_cutover:quiesce` to pause new work and complete in-flight work
#   2. manually monitor replication lag until 0
#   3. manually promote replica
#   4. run `rake online_cutover:promote` to route all traffic to promoted replica
#   5. run `rake online_cutover:resume` to resume work
#
# == Abort procedure
#
#   run `rake online_cutover:abort` to route all traffic to primary
#
module OnlineCutover
  class QuiesceTimeoutError < StandardError; end
  class InvalidPhaseError < StandardError; end
  class InvalidRoutingError < StandardError; end

  REDIS_KEY_PREFIX = 'online_cutover'
  REDIS_STATE_KEY  = "#{REDIS_KEY_PREFIX}:state"
  REDIS_CHANNEL    = "#{REDIS_KEY_PREFIX}:notifications"

  PHASE_NORMAL    = 'normal'
  PHASE_QUIESCING = 'quiescing'
  PHASES          = [PHASE_NORMAL, PHASE_QUIESCING].freeze

  ROUTING_NORMAL   = 'normal'
  ROUTING_PROMOTED = 'promoted'
  ROUTING_ABORTED  = 'aborted'
  ROUTINGS         = [ROUTING_NORMAL, ROUTING_PROMOTED, ROUTING_ABORTED].freeze

  SHARD_NORMAL   = 'normal'
  SHARD_PROMOTED = 'promoted'
  SHARD_ABORTED  = 'aborted'

  class Configuration
    # the primary database key that will be replaced
    attr_accessor :primary_database_key

    # the replica database key that will be promoted
    attr_accessor :replica_database_key

    # how long to block requests during quiescing phase before timing out
    attr_accessor :quiesce_timeout

    # ttl for redis state keys (should be longer than any expected cutover)
    attr_accessor :state_ttl

    # whether the replica is available
    attr_writer :replica_available

    # whether the replica is enabled
    attr_writer :replica_enabled

    # whether to enable cutover functionality
    attr_writer :enabled

    # whether to enable debug mode
    attr_writer :debug

    def initialize
      @primary_database_key = :primary
      @replica_database_key = :replica
      @quiesce_timeout      = 30.seconds
      @state_ttl            = 1.hour
      @replica_available    = true
      @replica_enabled      = true
      @enabled              = true
      @debug                = Rails.env.local?
    end

    def replica_available? = (@replica_available in Proc) ? @replica_available.call : !!@replica_available
    def replica_enabled?   = (@replica_enabled in Proc) ? @replica_enabled.call : !!@replica_enabled
    def enabled?           = (@enabled in Proc) ? @enabled.call : !!@enabled
    def debug?             = (@debug in Proc) ? @debug.call : !!@debug
  end

  class << self
    def configuration = @configuration ||= Configuration.new
    def configure
      yield configuration
    end

    # helper for accessing state singleton
    def state = State.instance

    def current_phase   = state.phase.to_s.inquiry
    def current_routing = state.routing.to_s.inquiry
    def current_shard
      shard = case current_routing
              when ROUTING_PROMOTED then SHARD_PROMOTED
              when ROUTING_ABORTED  then SHARD_ABORTED
              else SHARD_NORMAL
              end

      shard.to_s.inquiry
    end

    # state mutations used by operational rake tasks
    def set_phase!(phase)
      raise InvalidPhaseError, "invalid phase: #{phase}" unless PHASES.include?(phase)

      state.set_phase!(phase)
    end

    def set_routing!(routing)
      raise InvalidRoutingError, "invalid routing: #{routing}" unless ROUTINGS.include?(routing)

      state.set_routing!(routing)
    end

    # whether cutover is available i.e. replica available and enabled
    def available? = configuration.replica_available? && configuration.replica_enabled?

    # whether cutover is enabled
    def enabled? = configuration.enabled?

    # returns whether cutover is started i.e. we'er not in a nominal state
    def started? = !current_phase.normal? || !current_routing.normal?

    def status
      {
        quiesce_timeout: configuration.quiesce_timeout,
        phase: current_phase,
        routing: current_routing,
        shard: current_shard,
        available: available?,
        enabled: enabled?,
        started: started?,
      }
    end
  end

  class State
    DEFAULT_STATE = { phase: PHASE_NORMAL, routing: ROUTING_NORMAL }.freeze

    include Singleton

    attr_reader :phase,
                :routing

    def initialize
      @mutex   = Mutex.new
      @phase   = DEFAULT_STATE[:phase]
      @routing = DEFAULT_STATE[:routing]
    end

    def set_phase!(phase)
      @mutex.synchronize do
        state = current_state.merge(phase:)

        redis do |conn|
          conn.multi do |txn|
            txn.set(REDIS_STATE_KEY, JSON.generate(state), ex: OnlineCutover.configuration.state_ttl.to_i)
            txn.publish(REDIS_CHANNEL, JSON.generate(event: 'phase.changed', phase:))
          end
        end

        @phase = phase
      end
    end

    def set_routing!(routing)
      @mutex.synchronize do
        state = current_state.merge(routing:)

        redis do |conn|
          conn.multi do |txn|
            txn.set(REDIS_STATE_KEY, JSON.generate(state), ex: OnlineCutover.configuration.state_ttl.to_i)
            txn.publish(REDIS_CHANNEL, JSON.generate(event: 'routing.changed', routing:))
          end
        end

        @routing = routing
      end
    end

    def sync_from_redis!
      @mutex.synchronize do
        state = current_state

        @phase   = state[:phase]
        @routing = state[:routing]
      end
    end

    def update_local_phase(phase)
      @mutex.synchronize { @phase = phase }
    end

    def update_local_routing(routing)
      @mutex.synchronize { @routing = routing }
    end

    # helper for resetting state between tests
    def reset!
      @phase   = DEFAULT_STATE[:phase]
      @routing = DEFAULT_STATE[:routing]
    end

    private

    attr_writer :phase,
                :routing

    def current_state
      if state = redis { it.get(REDIS_STATE_KEY) }
        JSON.parse(state, symbolize_names: true)
      else
        DEFAULT_STATE
      end
    end

    def redis(&) = Rails.cache.redis.then(&)
  end

  module Model
    extend ActiveSupport::Concern

    class_methods do
      def connects_to_with_cutover(config: OnlineCutover.configuration)
        primary = config.primary_database_key
        replica = config.replica_database_key

        # NB(ezekg) we're using shards to leverage ActiveRecord's connected_to(shard:) for dynamic
        #           connection switching during cutover, not for traditional horizontal sharding.
        connects_to shards: {
          SHARD_NORMAL   => { writing: primary, reading: replica },
          SHARD_PROMOTED => { writing: replica, reading: replica },
          SHARD_ABORTED  => { writing: primary, reading: primary },
        }
      end
    end
  end

  class Middleware
    POLL_INTERVAL = 0.1.seconds

    def initialize(app)
      @app = app
    end

    def call(env)
      if OnlineCutover.current_phase.quiescing?
        wait_for_resume_or_timeout!
      end

      ActiveRecord::Base.connected_to(shard: OnlineCutover.current_shard) do
        @app.call(env)
      end
    rescue QuiesceTimeoutError
      [
        503,
        { 'Content-Type' => 'text/plain', 'Retry-After' => '5' },
        ['Service Unavailable'],
      ]
    end

    private

    def wait_for_resume_or_timeout!
      timeout  = OnlineCutover.configuration.quiesce_timeout
      deadline = Time.current + timeout

      while OnlineCutover.current_phase.quiescing?
        if Time.current > deadline
          raise QuiesceTimeoutError, "Quiesce timeout exceeded (#{timeout}s)"
        end

        sleep POLL_INTERVAL
      end
    end
  end

  class SidekiqMiddleware
    POLL_INTERVAL = 0.1.seconds

    def call(worker, job, queue)
      if OnlineCutover.current_phase.quiescing?
        wait_for_resume_or_retry!
      end

      ActiveRecord::Base.connected_to(shard: OnlineCutover.current_shard) do
        yield
      end
    end

    private

    def wait_for_resume_or_retry!
      timeout  = OnlineCutover.configuration.quiesce_timeout
      deadline = Time.current + timeout

      while OnlineCutover.current_phase.quiescing?
        if Time.current > deadline
          raise QuiesceTimeoutError, "Quiesce timeout exceeded (#{timeout}s) - job will be retried"
        end

        sleep POLL_INTERVAL
      end
    end
  end

  class Subscriber
    include Singleton

    def initialize
      @thread = nil
    end

    def start
      return if @thread&.alive?

      State.instance.sync_from_redis! # initial state

      @thread = Thread.new { subscribe }
      @thread.name = 'online_cutover_subscriber'
      @thread.abort_on_exception = true
    end

    def stop
      @thread&.kill
      @thread = nil
    end

    def running?
      !!@thread&.alive?
    end

    private

    def subscribe
      redis do |conn|
        conn.subscribe(REDIS_CHANNEL) do |on|
          on.message do |channel, message|
            handle_message(message)
          end
        end
      end
    end

    def handle_message(raw_message)
      message = JSON.parse(raw_message, symbolize_names: true)

      case message[:event]
      when 'phase.changed'
        State.instance.update_local_phase(message[:phase])
      when 'routing.changed'
        State.instance.update_local_routing(message[:routing])
      end
    end

    def redis(&) = Rails.cache.redis.then(&)
  end

  class Railtie < Rails::Railtie
    initializer 'online_cutover.middleware' do |app|
      app.config.after_initialize do
        next unless OnlineCutover.enabled?

        app.middleware.insert_before(
          ActiveRecord::Middleware::DatabaseSelector,
          OnlineCutover::Middleware
        )
      end
    end

    initializer 'online_cutover.active_record' do
      ActiveSupport.on_load(:active_record) do
        # configure shard-based connection switching for all models (still overridable per-model)
        Rails.application.config.after_initialize do
          next unless OnlineCutover.enabled?

          ApplicationRecord.include OnlineCutover::Model
          ApplicationRecord.connects_to_with_cutover
        end
      end
    end

    initializer 'online_cutover.sidekiq' do
      next unless defined?(Sidekiq)

      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add OnlineCutover::SidekiqMiddleware
        end
      end
    end

    config.after_initialize do
      next unless OnlineCutover.enabled?

      # start Pub/Sub subscriber
      OnlineCutover::Subscriber.instance.start
    end

    config.after_initialize do
      # graceful shutdown
      at_exit do
        OnlineCutover::Subscriber.instance.stop if OnlineCutover::Subscriber.instance.running?
      end
    end
  end
end
