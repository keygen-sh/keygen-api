# frozen_string_literal: true

require 'sidekiq'

require_relative 'dual_writes/context'
require_relative 'dual_writes/operation'
require_relative 'dual_writes/bulk_operation'
require_relative 'dual_writes/strategy/clickhouse'

module DualWrites
  class Error < StandardError; end
  class ReplicationError < Error; end
  class ConfigurationError < Error; end

  # registry of dynamic abstract base classes for each database
  @base_classes = {}

  class << self
    def base_class_for(database)
      @base_classes[database] ||= begin
        class_name = "#{database.to_s.camelize}Record"

        # create and name the base class (Rails requires a name for connects_to)
        base = Class.new(ActiveRecord::Base)
        const_set(class_name, base)

        base.abstract_class = true
        base.connects_to database: {
          writing: database,
          reading: database,
        }

        base
      end
    end

    def configuration = @configuration ||= Configuration.new
    def configuration=(config)
      @configuration = config
    end

    def configure
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :retry_attempts

    def initialize
      @retry_attempts = 5
    end
  end

  class Strategy
    class << self
      def lookup(name)
        case name
        when Class
          name
        when Symbol, String
          const_get(name.to_s.camelize)
        else
          raise ConfigurationError, "strategy must be a symbol or class, got #{name.class}"
        end
      rescue NameError
        raise ConfigurationError, "unknown strategy: #{name.inspect}"
      end
    end

    attr_reader :replica_class,
                :config

    def initialize(replica_class, config = {})
      @replica_class = replica_class
      @config        = config
    end

    def execute(operation)
      operation.execute_with(self)
    end

    def execute_bulk(operation)
      operation.execute_with(self)
    end

    def handle_create(operation)
      raise NotImplementedError, "#{self.class}#handle_create must be implemented"
    end

    def handle_update(operation)
      raise NotImplementedError, "#{self.class}#handle_update must be implemented"
    end

    def handle_destroy(operation)
      raise NotImplementedError, "#{self.class}#handle_destroy must be implemented"
    end

    def handle_insert_all(operation)
      raise NotImplementedError, "#{self.class}#handle_insert_all must be implemented"
    end

    def handle_upsert_all(operation)
      raise NotImplementedError, "#{self.class}#handle_upsert_all must be implemented"
    end
  end

  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :dual_writes_config, instance_accessor: false, default: nil

      # async replication: enqueue jobs after commit (no rollback on failure)
      after_create_commit  :replicate_create_async,  if: :should_replicate_async?
      after_update_commit  :replicate_update_async,  if: :should_replicate_async?
      after_destroy_commit :replicate_destroy_async, if: :should_replicate_async?

      # sync replication: run inside transaction (rollback primary on failure)
      after_create  :replicate_create_sync,  if: :should_replicate_sync?
      after_update  :replicate_update_sync,  if: :should_replicate_sync?
      after_destroy :replicate_destroy_sync, if: :should_replicate_sync?
    end

    class_methods do
      def dual_writes(to:, strategy:, sync: false, **strategy_config)
        databases = Array(to)

        raise ConfigurationError, 'to must be a symbol or array of symbols' unless
          databases.all? { it.is_a?(Symbol) }

        raise ConfigurationError, 'to cannot be empty' if
          databases.empty?

        # validate strategy can be looked up
        Strategy.lookup(strategy)

        # auto-generate model classes for each database e.g. RequestLog with to: :clickhouse
        # creates RequestLog::Clickhouse that inherits from DualWrites::ClickhouseRecord
        databases.each do |database|
          database_class_name = database.to_s.camelize

          next if const_defined?(database_class_name, false)

          base_class = DualWrites.base_class_for(database)
          table      = table_name

          database_class = Class.new(base_class) do
            self.table_name = table
          end

          const_set(database_class_name, database_class)
        end

        self.dual_writes_config = {
          to: databases,
          sync:,
          strategy:,
          strategy_config:,
        }.freeze
      end

      # override bulk insert methods to automatically replicate
      def insert_all(attributes, **options)
        result = super

        replicate_bulk(:insert_all, attributes)

        result
      end

      def insert_all!(attributes, **options)
        result = super

        replicate_bulk(:insert_all, attributes)

        result
      end

      def upsert_all(attributes, **options)
        result = super

        replicate_bulk(:upsert_all, attributes)

        result
      end

      private

      def replicate_bulk(operation, records)
        return if
          dual_writes_config.nil?

        performed_at    = Time.current
        config          = dual_writes_config
        strategy_config = resolved_strategy_config

        config[:to].each do |database|
          if config[:sync]
            BulkReplicationJob.perform_now(
              class_name: name,
              performed_at:,
              operation:,
              database:,
              records:,
              strategy_config:,
            )
          else
            BulkReplicationJob.perform_later(
              class_name: name,
              performed_at:,
              operation:,
              database:,
              records:,
              strategy_config:,
            )
          end
        end
      end

      def resolved_strategy_config
        dual_writes_config[:strategy_config].transform_values do |value|
          value.is_a?(Proc) ? value.call : value
        end
      end
    end

    private

    def should_replicate_async?
      return false if
        self.class.dual_writes_config.nil?

      !self.class.dual_writes_config[:sync]
    end

    def should_replicate_sync?
      return false if
        self.class.dual_writes_config.nil?

      self.class.dual_writes_config[:sync]
    end

    def replicate_create_async  = replicate_async(:create)
    def replicate_update_async  = replicate_async(:update)
    def replicate_destroy_async = replicate_async(:destroy)

    def replicate_create_sync  = replicate_sync(:create)
    def replicate_update_sync  = replicate_sync(:update)
    def replicate_destroy_sync = replicate_sync(:destroy)

    def replicate_async(operation)
      performed_at    = Time.current
      config          = self.class.dual_writes_config
      strategy_config = resolved_strategy_config

      config[:to].each do |database|
        ReplicationJob.perform_later(
          class_name: self.class.name,
          attributes:,
          performed_at:,
          operation:,
          database:,
          strategy_config:,
        )
      end
    end

    def replicate_sync(operation)
      performed_at    = Time.current
      config          = self.class.dual_writes_config
      strategy_config = resolved_strategy_config

      config[:to].each do |database|
        ReplicationJob.perform_now(
          class_name: self.class.name,
          attributes:,
          performed_at:,
          operation:,
          database:,
          strategy_config:,
        )
      end
    end

    def resolved_strategy_config
      self.class.dual_writes_config[:strategy_config].transform_values do |value|
        value.is_a?(Proc) ? instance_exec(&value) : value
      end
    end
  end

  class ReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] }

    discard_on ActiveJob::DeserializationError
    rescue_from StandardError do |error|
      if executions < DualWrites.configuration.retry_attempts
        retry_job(wait: :polynomially_longer)
      else
        raise error
      end
    end

    def perform(operation:, class_name:, attributes:, performed_at:, database:, strategy_config: {})
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      config         = klass.dual_writes_config
      database_class = klass.const_get(database.to_s.camelize)
      strategy       = Strategy.lookup(config[:strategy]).new(database_class, strategy_config)
      context        = Context.new(performed_at:)
      operation      = Operation.lookup(operation).new(attributes, context:)

      strategy.execute(operation)
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{database} not established: #{e.message}"
    end
  end

  class BulkReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] }

    discard_on ActiveJob::DeserializationError
    rescue_from StandardError do |error|
      if executions < DualWrites.configuration.retry_attempts
        retry_job(wait: :polynomially_longer)
      else
        raise error
      end
    end

    def perform(operation:, class_name:, database:, performed_at:, records:, strategy_config: {})
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      config         = klass.dual_writes_config
      database_class = klass.const_get(database.to_s.camelize)
      strategy       = Strategy.lookup(config[:strategy]).new(database_class, strategy_config)
      context        = Context.new(performed_at:)
      operation      = BulkOperation.lookup(operation).new(records, context:)

      strategy.execute_bulk(operation)
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{database} not established: #{e.message}"
    end
  end
end
