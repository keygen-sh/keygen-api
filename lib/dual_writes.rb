# frozen_string_literal: true

module DualWrites
  class Error < StandardError; end
  class ReplicationError < Error; end
  class ConfigurationError < Error; end

  # Registry of abstract base classes for each shard.
  # e.g., DualWrites.base_class_for(:clickhouse) returns an abstract class
  # that connects to the :clickhouse shard.
  @base_classes = {}

  class << self
    def base_class_for(shard)
      @base_classes[shard] ||= begin
        class_name = "#{shard.to_s.camelize}Record"

        # Create and name the class first (Rails requires a name for connects_to)
        base = Class.new(ActiveRecord::Base)
        const_set(class_name, base)

        # Now configure it
        base.abstract_class = true
        base.connects_to database: { writing: shard }

        base
      end
    end
  end

  # Concern to be included in models that need dual writing
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :dual_writes_config, instance_accessor: false, default: nil
      class_attribute :dual_writes_enabled, instance_accessor: false, default: true

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
      # Configure dual writes for this model
      #
      # @param to [Symbol, Array<Symbol>] the replica shard(s) to write to
      # @param sync [Boolean] whether to replicate synchronously inside the transaction (default: false)
      # @param strategy [Symbol] replication strategy - :standard (default) or :append_only.
      #   Use :append_only for append-only databases like ClickHouse with ReplacingMergeTree.
      #   In :append_only mode, all operations become inserts and deletes are skipped.
      # @param resolve_with [Symbol, nil] column to use for conflict resolution (e.g., :updated_at).
      #   When set, only applies changes if the incoming value is newer than the existing value.
      #   This prevents out-of-order job execution from overwriting newer data with older data.
      #   Note: resolve_with is ignored when using :append_only strategy.
      #
      # @example
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse
      #   end
      #
      # @example with multiple replicas
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: %i[clickhouse analytics]
      #   end
      #
      # @example with synchronous replication
      #   class EventLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, sync: true
      #   end
      #
      # @example with insert-only strategy for ClickHouse (ReplacingMergeTree)
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, strategy: :append_only
      #   end
      #
      # @example with conflict resolution using lock_version (recommended for critical data)
      #   class License < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, resolve_with: :lock_version
      #   end
      #
      # @example with auto-detected conflict resolution (uses lock_version if present, else updated_at)
      #   class License < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :clickhouse, resolve_with: true
      #   end
      #
      def dual_writes(to:, sync: false, strategy: :standard, resolve_with: nil)
        shards = Array(to)

        raise ConfigurationError, 'to must be a symbol or array of symbols' unless
          shards.all? { it.is_a?(Symbol) }

        raise ConfigurationError, 'to cannot be empty' if
          shards.empty?

        raise ConfigurationError, 'resolve_with must be a symbol or true' if
          resolve_with.present? && !resolve_with.is_a?(Symbol) && resolve_with != true

        raise ConfigurationError, 'strategy must be :standard or :append_only' unless
          %i[standard append_only].include?(strategy)

        # auto-detect resolution column: prefer lock_version, fall back to updated_at
        resolved_column = case resolve_with
                          when true
                            if column_names.include?('lock_version')
                              :lock_version
                            elsif column_names.include?('updated_at')
                              :updated_at
                            else
                              raise ConfigurationError, 'resolve_with: true requires lock_version or updated_at column'
                            end
                          when Symbol
                            resolve_with
                          end

        # Auto-generate replica model classes for each shard.
        # e.g., RequestLog with to: :clickhouse creates RequestLog::Clickhouse
        # that inherits from DualWrites::ClickhouseRecord and has its own schema cache.
        shards.each do |shard|
          replica_class_name = shard.to_s.camelize

          next if const_defined?(replica_class_name, false)

          base_class = DualWrites.base_class_for(shard)
          table = table_name

          replica_class = Class.new(base_class) do
            self.table_name = table
          end

          const_set(replica_class_name, replica_class)
        end

        self.dual_writes_config = {
          to: shards,
          sync:,
          strategy:,
          resolve_with: resolved_column,
        }.freeze
      end

      # Temporarily disable dual writes for a block
      #
      # @example
      #   RequestLog.without_dual_writes do
      #     RequestLog.create!(...)
      #   end
      #
      def without_dual_writes(&)
        original = dual_writes_enabled
        self.dual_writes_enabled = false
        yield
      ensure
        self.dual_writes_enabled = original
      end

      # Temporarily enable synchronous dual writes for a block
      #
      # @example
      #   RequestLog.with_sync_dual_writes do
      #     RequestLog.create!(...)
      #   end
      #
      def with_sync_dual_writes(&)
        return yield if dual_writes_config.nil?

        original_config = dual_writes_config
        self.dual_writes_config = original_config.merge(sync: true)
        yield
      ensure
        self.dual_writes_config = original_config
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

      def replicate_bulk(operation, attributes)
        return if dual_writes_config.nil?
        return unless dual_writes_enabled

        config = dual_writes_config

        config[:to].each do |shard|
          if config[:sync]
            BulkReplicationJob.perform_now(
              operation: operation.to_s,
              class_name: name,
              attributes: attributes.map { |attr| attr.transform_keys(&:to_s) },
              shard: shard.to_s,
            )
          else
            BulkReplicationJob.perform_later(
              operation: operation.to_s,
              class_name: name,
              attributes: attributes.map { |attr| attr.transform_keys(&:to_s) },
              shard: shard.to_s,
            )
          end
        end
      end
    end

    private

    def should_replicate_async?
      return false unless self.class.dual_writes_enabled
      return false if self.class.dual_writes_config.nil?

      !self.class.dual_writes_config[:sync]
    end

    def should_replicate_sync?
      return false unless self.class.dual_writes_enabled
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
      config = self.class.dual_writes_config
      attrs  = replication_attributes

      config[:to].each do |shard|
        ReplicationJob.perform_later(
          operation: operation.to_s,
          class_name: self.class.name,
          primary_key: id,
          attributes: attrs,
          shard: shard.to_s,
        )
      end
    end

    def replicate_sync(operation)
      config = self.class.dual_writes_config
      attrs  = replication_attributes

      config[:to].each do |shard|
        ReplicationJob.perform_now(
          operation: operation.to_s,
          class_name: self.class.name,
          primary_key: id,
          attributes: attrs,
          shard: shard.to_s,
        )
      end
    end

    def replication_attributes
      attributes.transform_keys(&:to_s)
    end
  end

  class ReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] || :default }

    retry_on ActiveRecord::ActiveRecordError, wait: :polynomially_longer, attempts: 5

    discard_on ActiveJob::DeserializationError

    def perform(operation:, class_name:, primary_key:, attributes:, shard:)
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      config = klass.dual_writes_config

      replicate_to(
        operation.to_sym,
        klass,
        shard.to_sym,
        primary_key,
        attributes,
        strategy: config[:strategy],
        resolve_with: config[:resolve_with],
      )
    end

    private

    def replicate_to(operation, klass, shard, primary_key, attributes, strategy: :standard, resolve_with: nil)
      # Get the auto-generated replica class (e.g., RequestLog::Clickhouse)
      # which connects directly to the shard and has its own schema cache.
      replica_class = klass.const_get(shard.to_s.camelize)

      case strategy
      when :append_only
        # No transaction needed for append-only (ClickHouse doesn't support them)
        replicate_append_only(operation, replica_class, primary_key, attributes)
      when :standard
        replica_class.transaction do
          if resolve_with.present?
            replicate_with_resolution(operation, replica_class, primary_key, attributes, resolve_with)
          else
            replicate_without_resolution(operation, replica_class, primary_key, attributes)
          end
        end
      else
        raise ReplicationError, "unknown strategy: #{strategy}"
      end
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{shard} not established: #{e.message}"
    end

    # Insert-only replication for append-only databases like ClickHouse.
    # All operations become inserts; updates insert new versions (ReplacingMergeTree handles dedup),
    # and deletes insert a tombstone row with is_deleted = 1.
    def replicate_append_only(operation, klass, primary_key, attributes)
      # Serialize any non-primitive values to JSON for ClickHouse compatibility
      serialized = attributes.transform_values { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.to_json : v }

      case operation
      when :create, :update
        klass.insert!(serialized.merge('id' => primary_key, 'is_deleted' => 0))
      when :destroy
        # Insert a tombstone row with is_deleted = 1
        # ReplacingMergeTree(ver, is_deleted) will handle cleanup
        klass.insert!(serialized.merge('id' => primary_key, 'is_deleted' => 1))
      else
        raise ReplicationError, "unknown operation: #{operation}"
      end
    end

    def replicate_without_resolution(operation, klass, primary_key, attributes)
      case operation
      when :create
        klass.upsert(attributes.merge('id' => primary_key), unique_by: :id)
      when :update
        klass.where(id: primary_key).update_all(attributes.except('id'))
      when :destroy
        klass.where(id: primary_key).delete_all
      else
        raise ReplicationError, "unknown operation: #{operation}"
      end
    end

    def replicate_with_resolution(operation, klass, primary_key, attributes, resolve_with)
      resolve_column    = resolve_with.to_s
      incoming_resolved = attributes[resolve_column]

      raise ConfigurationError, "resolve_with column #{resolve_column.inspect} not found in attributes" if
        incoming_resolved.nil?

      case operation
      when :create
        # insert, or update if conflict and incoming is newer
        begin
          klass.insert(attributes.merge('id' => primary_key))
        rescue ActiveRecord::RecordNotUnique
          klass.where(id: primary_key)
               .where(klass.arel_table[resolve_column].lt(incoming_resolved))
               .update_all(attributes.except('id'))
        end
      when :update
        # only update if record exists and incoming is newer
        klass.where(id: primary_key)
             .where(klass.arel_table[resolve_column].lt(incoming_resolved))
             .update_all(attributes.except('id'))
      when :destroy
        # only delete if record exists and incoming is newer or equal
        klass.where(id: primary_key)
             .where(klass.arel_table[resolve_column].lteq(incoming_resolved))
             .delete_all
      else
        raise ReplicationError, "unknown operation: #{operation}"
      end
    end
  end

  class BulkReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] || :default }

    retry_on ActiveRecord::ActiveRecordError, wait: :polynomially_longer, attempts: 5

    discard_on ActiveJob::DeserializationError

    def perform(operation:, class_name:, attributes:, shard:)
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      config = klass.dual_writes_config
      replica_class = klass.const_get(shard.to_s.camelize)

      case operation
      when 'insert_all'
        replicate_insert_all(replica_class, attributes, strategy: config[:strategy])
      when 'upsert_all'
        replicate_upsert_all(replica_class, attributes, strategy: config[:strategy])
      else
        raise ReplicationError, "unknown bulk operation: #{operation}"
      end
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{shard} not established: #{e.message}"
    end

    private

    def replicate_insert_all(klass, attributes, strategy:)
      case strategy
      when :append_only
        # Serialize and add is_deleted for ClickHouse
        records = attributes.map do |attrs|
          serialized = attrs.transform_values { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.to_json : v }
          serialized.merge('is_deleted' => 0)
        end
        klass.insert_all!(records)
      when :standard
        klass.insert_all!(attributes)
      else
        raise ReplicationError, "unknown strategy: #{strategy}"
      end
    end

    def replicate_upsert_all(klass, attributes, strategy:)
      case strategy
      when :append_only
        # For append-only, upsert becomes insert (ReplacingMergeTree handles dedup)
        records = attributes.map do |attrs|
          serialized = attrs.transform_values { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.to_json : v }
          serialized.merge('is_deleted' => 0)
        end
        klass.insert_all!(records)
      when :standard
        klass.upsert_all(attributes)
      else
        raise ReplicationError, "unknown strategy: #{strategy}"
      end
    end
  end
end
