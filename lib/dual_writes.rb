# frozen_string_literal: true

require 'sidekiq'

module DualWrites
  DUAL_WRITES_REPLICATION_RETRY_ATTEMPTS = 5

  class Error < StandardError; end
  class ReplicationError < Error; end
  class ConfigurationError < Error; end

  # Registry of abstract base classes for each database.
  # e.g., DualWrites.base_class_for(:clickhouse) returns an abstract class
  # that connects to the :clickhouse database.
  @base_classes = {}

  class << self
    def base_class_for(database)
      @base_classes[database] ||= begin
        class_name = "#{database.to_s.camelize}Record"

        # Create and name the class first (Rails requires a name for connects_to)
        base = Class.new(ActiveRecord::Base)
        const_set(class_name, base)

        # Now configure it
        base.abstract_class = true
        base.connects_to database: {
          writing: database,
          reading: database,
        }

        base
      end
    end
  end

  # Base class for replication strategies.
  # Subclass this to implement custom replication logic for different databases.
  #
  # Strategies use the command pattern with Operation and BulkOperation objects
  # to cleanly separate record attributes from execution context (like performed_at).
  #
  # Operations use double dispatch to call the appropriate handler method on the
  # strategy, enabling clean polymorphic behavior without switch statements.
  #
  # @example Creating a custom strategy
  #   class MyStrategy < DualWrites::Strategy
  #     def handle_create(operation)
  #       # custom create logic using operation.attributes and operation.performed_at
  #     end
  #
  #     def handle_update(operation)
  #       # custom update logic
  #     end
  #
  #     def handle_destroy(operation)
  #       # custom destroy logic
  #     end
  #   end
  #
  # @example Using a custom strategy
  #   class MyModel < ApplicationRecord
  #     include DualWrites::Model
  #     dual_writes to: :my_database, strategy: MyStrategy
  #   end
  #
  class Strategy
    class << self
      # Look up a strategy class by name.
      #
      # @param name [Symbol, String, Class] the strategy name or class
      # @return [Class] the strategy class
      # @raise [ConfigurationError] if the strategy is not found
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

    attr_reader :replica_class

    def initialize(replica_class)
      @replica_class = replica_class
    end

    # Execute a single-record operation using double dispatch.
    #
    # @param operation [Operation] the operation to execute (Create, Update, or Destroy)
    def execute(operation)
      operation.execute_with(self)
    end

    # Execute a bulk operation using double dispatch.
    #
    # @param operation [BulkOperation] the operation to execute (InsertAll or UpsertAll)
    def execute_bulk(operation)
      operation.execute_with(self)
    end

    # @!group Single Record Handlers

    # Handle a create operation.
    # @param operation [Operation::Create] the create operation
    def handle_create(operation)
      raise NotImplementedError, "#{self.class}#handle_create must be implemented"
    end

    # Handle an update operation.
    # @param operation [Operation::Update] the update operation
    def handle_update(operation)
      raise NotImplementedError, "#{self.class}#handle_update must be implemented"
    end

    # Handle a destroy operation.
    # @param operation [Operation::Destroy] the destroy operation
    def handle_destroy(operation)
      raise NotImplementedError, "#{self.class}#handle_destroy must be implemented"
    end

    # @!endgroup

    # @!group Bulk Operation Handlers

    # Handle a bulk insert operation.
    # @param operation [BulkOperation::InsertAll] the insert_all operation
    def handle_insert_all(operation)
      raise NotImplementedError, "#{self.class}#handle_insert_all must be implemented"
    end

    # Handle a bulk upsert operation.
    # @param operation [BulkOperation::UpsertAll] the upsert_all operation
    def handle_upsert_all(operation)
      raise NotImplementedError, "#{self.class}#handle_upsert_all must be implemented"
    end

    # @!endgroup
  end

  # Concern to be included in models that need dual writing
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
      # Configure dual writes for this model.
      #
      # @param to [Symbol, Array<Symbol>] the database(s) to write to
      # @param strategy [Symbol, Class] replication strategy class or name.
      #   Built-in strategies: :clickhouse.
      #   Use :clickhouse for ClickHouse with ReplacingMergeTree (insert-only with is_deleted flag).
      # @param sync [Boolean] whether to replicate synchronously inside the transaction (default: false)
      # @param ttl [Proc, nil] a proc that returns the TTL in seconds.
      #   Called in the context of the model instance. Used for ClickHouse TTL expiration.
      #
      # @example Basic usage
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, strategy: :clickhouse
      #   end
      #
      # @example With multiple replicas
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: %i[clickhouse analytics], strategy: :clickhouse
      #   end
      #
      # @example With synchronous replication
      #   class EventLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, strategy: :clickhouse, sync: true
      #   end
      #
      # @example With TTL expiration
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, strategy: :clickhouse,
      #       ttl: -> { account.request_log_retention_duration }
      #   end
      #
      # @example With custom strategy
      #   class MyModel < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :my_database, strategy: MyCustomStrategy
      #   end
      #
      def dual_writes(to:, strategy:, sync: false, ttl: nil)
        databases = Array(to)

        raise ConfigurationError, 'to must be a symbol or array of symbols' unless
          databases.all? { it.is_a?(Symbol) }

        raise ConfigurationError, 'to cannot be empty' if
          databases.empty?

        # Validate strategy can be looked up
        Strategy.lookup(strategy)

        # Auto-generate model classes for each database.
        # e.g., RequestLog with to: :clickhouse creates RequestLog::Clickhouse
        # that inherits from DualWrites::ClickhouseRecord and has its own schema cache.
        databases.each do |database|
          database_class_name = database.to_s.camelize

          next if const_defined?(database_class_name, false)

          base_class = DualWrites.base_class_for(database)
          table = table_name

          database_class = Class.new(base_class) do
            self.table_name = table
          end

          const_set(database_class_name, database_class)
        end

        self.dual_writes_config = {
          to: databases,
          sync:,
          strategy:,
          ttl:,
        }.freeze
      end

      # Override bulk insert methods to automatically replicate
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
        return if dual_writes_config.nil?

        performed_at = Time.current
        config       = dual_writes_config

        config[:to].each do |database|
          if config[:sync]
            BulkReplicationJob.perform_now(
              operation: operation.to_s,
              class_name: name,
              records: records.map { |record| record.transform_keys(&:to_s) },
              performed_at:,
              database: database.to_s,
            )
          else
            BulkReplicationJob.perform_later(
              operation: operation.to_s,
              class_name: name,
              records: records.map { |record| record.transform_keys(&:to_s) },
              performed_at:,
              database: database.to_s,
            )
          end
        end
      end
    end

    private

    def should_replicate_async?
      return false if self.class.dual_writes_config.nil?

      !self.class.dual_writes_config[:sync]
    end

    def should_replicate_sync?
      return false if self.class.dual_writes_config.nil?

      self.class.dual_writes_config[:sync]
    end

    def replicate_create_async  = replicate_async(:create)
    def replicate_update_async  = replicate_async(:update)
    def replicate_destroy_async = replicate_async(:destroy)

    def replicate_create_sync  = replicate_sync(:create)
    def replicate_update_sync  = replicate_sync(:update)
    def replicate_destroy_sync = replicate_sync(:destroy)

    def replicate_async(operation)
      performed_at = Time.current
      config       = self.class.dual_writes_config
      attrs        = replication_attributes

      config[:to].each do |database|
        ReplicationJob.perform_later(
          operation: operation.to_s,
          class_name: self.class.name,
          attributes: attrs,
          performed_at:,
          database: database.to_s,
        )
      end
    end

    def replicate_sync(operation)
      performed_at = Time.current
      config       = self.class.dual_writes_config
      attrs        = replication_attributes

      config[:to].each do |database|
        ReplicationJob.perform_now(
          operation: operation.to_s,
          class_name: self.class.name,
          attributes: attrs,
          performed_at:,
          database: database.to_s,
        )
      end
    end

    def replication_attributes
      attrs = attributes.transform_keys(&:to_s)

      if (ttl_proc = self.class.dual_writes_config[:ttl])
        attrs['ttl'] = instance_exec(&ttl_proc)
      end

      attrs
    end
  end

  class ReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] }

    discard_on ActiveJob::DeserializationError
    retry_on StandardError,
      attempts: DUAL_WRITES_REPLICATION_RETRY_ATTEMPTS,
      wait: :polynomially_longer

    def perform(operation:, class_name:, attributes:, performed_at:, database:)
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      config = klass.dual_writes_config
      database_class = klass.const_get(database.to_s.camelize)
      strategy = Strategy.lookup(config[:strategy]).new(database_class)

      operation = Operation.lookup(operation).new(attributes, performed_at:)
      strategy.execute(operation)
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{database} not established: #{e.message}"
    end
  end

  class BulkReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] }

    discard_on ActiveJob::DeserializationError
    retry_on StandardError,
      attempts: DUAL_WRITES_REPLICATION_RETRY_ATTEMPTS,
      wait: :polynomially_longer

    def perform(operation:, class_name:, database:, performed_at:, records:)
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      config = klass.dual_writes_config
      database_class = klass.const_get(database.to_s.camelize)
      strategy = Strategy.lookup(config[:strategy]).new(database_class)

      operation = BulkOperation.lookup(operation).new(records, performed_at:)
      strategy.execute_bulk(operation)
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{database} not established: #{e.message}"
    end
  end
end

# Load operation classes
require_relative 'dual_writes/operation'
require_relative 'dual_writes/bulk_operation'

# Load built-in strategies
require_relative 'dual_writes/strategy/clickhouse'
