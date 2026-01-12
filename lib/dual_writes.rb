# frozen_string_literal: true

module DualWrites
  class Error < StandardError; end
  class ReplicationError < Error; end
  class ConfigurationError < Error; end

  Context = Data.define(:performed_at) do
    def initialize(performed_at: Time.current) = super
  end

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

  class Operation
    class << self
      def lookup(name)
        const_get("#{self.name}::#{name.to_s.camelize}")
      rescue NameError
        raise ArgumentError, "unknown operation: #{name.inspect}"
      end
    end

    attr_reader :attributes,
                :context

    def initialize(attributes, context:)
      @attributes = attributes
      @context    = context
    end

    def execute_with(strategy)
      raise NotImplementedError, "#{self.class}#execute_with must be implemented"
    end

    class Create < Operation
      def execute_with(strategy) = strategy.handle_create(self)
    end

    class Update < Operation
      def execute_with(strategy) = strategy.handle_update(self)
    end

    class Destroy < Operation
      def execute_with(strategy) = strategy.handle_destroy(self)
    end
  end

  class BulkOperation
    class << self
      def lookup(name)
        const_get("#{self.name}::#{name.to_s.camelize}")
      rescue NameError
        raise ArgumentError, "unknown bulk operation: #{name.inspect}"
      end
    end

    attr_reader :records,
                :context

    def initialize(records, context:)
      @records = records
      @context = context
    end

    def execute_with(strategy)
      raise NotImplementedError, "#{self.class}#execute_with must be implemented"
    end

    class InsertAll < BulkOperation
      def execute_with(strategy) = strategy.handle_insert_all(self)
    end

    class UpsertAll < BulkOperation
      def execute_with(strategy) = strategy.handle_upsert_all(self)
    end
  end

  # abstract strategy interface
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

  class Strategy::Clickhouse < Strategy
    def handle_create(operation)
      insert_record(operation.attributes, is_deleted: 0, ver: operation.context.performed_at)
    end

    def handle_update(operation)
      insert_record(operation.attributes, is_deleted: 0, ver: operation.context.performed_at)
    end

    def handle_destroy(operation)
      insert_record(operation.attributes, is_deleted: 1, ver: operation.context.performed_at)
    end

    def handle_insert_all(operation)
      insert_records(operation.records, is_deleted: 0, ver: operation.context.performed_at)
    end

    def handle_upsert_all(operation)
      # upsert becomes insert (ReplacingMergeTree handles dedup)
      insert_records(operation.records, is_deleted: 0, ver: operation.context.performed_at)
    end

    private

    def insert_record(attributes, is_deleted:, ver:)
      replica_class.insert!(with_metadata(attributes, is_deleted:, ver:))
    end

    def insert_records(records, is_deleted:, ver:)
      records = records.map { with_metadata(it, is_deleted:, ver:) }

      replica_class.insert_all!(records)
    end

    def with_metadata(attributes, is_deleted:, ver:)
      attrs = attributes.dup

      attrs['is_deleted'] = is_deleted if replica_class.column_names.include?('is_deleted')
      attrs['ver']        = ver if replica_class.column_names.include?('ver')
      attrs['ttl']        = config[:clickhouse_ttl] if replica_class.column_names.include?('ttl')

      attrs
    end
  end

  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :dual_writes_config, instance_accessor: false, default: nil

      # async replication: enqueue jobs after commit (no rollback on failure)
      after_create_commit  :replicate_create,  if: :should_replicate_async?
      after_update_commit  :replicate_update,  if: :should_replicate_async?
      after_destroy_commit :replicate_destroy, if: :should_replicate_async?

      # sync replication: run inside transaction (rollback primary on failure)
      after_create  :replicate_create,  if: :should_replicate_sync?
      after_update  :replicate_update,  if: :should_replicate_sync?
      after_destroy :replicate_destroy, if: :should_replicate_sync?
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

        replicate_bulk(:insert_all, attributes) if
          should_replicate_bulk?

        result
      end

      def insert_all!(attributes, **options)
        result = super

        replicate_bulk(:insert_all, attributes) if
          should_replicate_bulk?

        result
      end

      def upsert_all(attributes, **options)
        result = super

        replicate_bulk(:upsert_all, attributes) if
          should_replicate_bulk?

        result
      end

      private

      def should_replicate_bulk? = dual_writes_config.present?

      def replicate_bulk(operation, records)
        return unless should_replicate_bulk?

        config          = dual_writes_config
        strategy_config = config[:strategy_config].transform_values { it.is_a?(Proc) ? it.call : it }
        performed_at    = Time.current

        config[:to].each do |database|
          params = {
            class_name: name,
            performed_at:,
            operation:,
            database:,
            records:,
            strategy_config:,
          }

          if config[:sync]
            BulkReplicationJob.perform_now(**params)
          else
            BulkReplicationJob.perform_later(**params)
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

    def replicate_create  = replicate(:create)
    def replicate_update  = replicate(:update)
    def replicate_destroy = replicate(:destroy)

    def replicate(operation)
      config          = self.class.dual_writes_config
      strategy_config = config[:strategy_config].transform_values { it.is_a?(Proc) ? instance_exec(&it) : it }
      performed_at    = Time.current

      config[:to].each do |database|
        params = {
          class_name: self.class.name,
          attributes:,
          performed_at:,
          operation:,
          database:,
          strategy_config:,
        }

        if config[:sync]
          ReplicationJob.perform_now(**params)
        else
          ReplicationJob.perform_later(**params)
        end
      end
    end
  end

  class ReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] }

    discard_on ActiveJob::DeserializationError
    rescue_from StandardError do |error| # FIXME(ezekg) rails doesn't support dynamic attempts proc
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
