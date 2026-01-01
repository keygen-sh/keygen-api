# frozen_string_literal: true

module DualWrites
  class Error < StandardError; end
  class ReplicationError < Error; end
  class ConfigurationError < Error; end

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
      # @param to [Symbol] the primary database shard (default: :primary)
      # @param replicates_to [Array<Symbol>] the replica shards to write to
      # @param async [Boolean] whether to replicate asynchronously via background job (default: true)
      #
      # @example
      #   class RequestLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :primary, replicates_to: %i[analytics]
      #   end
      #
      # @example with synchronous replication
      #   class EventLog < ApplicationRecord
      #     include DualWrites::Model
      #
      #     dual_writes to: :primary, replicates_to: %i[analytics], async: false
      #   end
      #
      def dual_writes(to: :primary, replicates_to:, async: true)
        raise ConfigurationError, 'replicates_to must be an array of symbols' unless
          replicates_to.is_a?(Array) && replicates_to.all? { it.is_a?(Symbol) }

        raise ConfigurationError, 'replicates_to cannot be empty' if
          replicates_to.empty?

        self.dual_writes_config = {
          primary: to,
          replicates_to: replicates_to,
          async: async,
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
        self.dual_writes_config = original_config.merge(async: false)
        yield
      ensure
        self.dual_writes_config = original_config
      end
    end

    private

    def should_replicate_async?
      return false unless self.class.dual_writes_enabled
      return false if self.class.dual_writes_config.nil?

      self.class.dual_writes_config[:async]
    end

    def should_replicate_sync?
      return false unless self.class.dual_writes_enabled
      return false if self.class.dual_writes_config.nil?

      !self.class.dual_writes_config[:async]
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

      config[:replicates_to].each do |replica|
        ReplicationJob.perform_later(
          operation: operation.to_s,
          class_name: self.class.name,
          primary_key: id,
          attributes: attrs,
          replica: replica.to_s,
        )
      end
    end

    def replicate_sync(operation)
      config = self.class.dual_writes_config
      attrs  = replication_attributes

      config[:replicates_to].each do |replica|
        ReplicationJob.perform_now(
          operation: operation.to_s,
          class_name: self.class.name,
          primary_key: id,
          attributes: attrs,
          replica: replica.to_s,
        )
      end
    end

    def replication_attributes
      attributes.transform_keys(&:to_s)
    end
  end

  class ReplicationJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:dual_writes] || :default }

    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    discard_on ActiveJob::DeserializationError

    def perform(operation:, class_name:, primary_key:, attributes:, replica:)
      klass = class_name.constantize

      unless klass.respond_to?(:dual_writes_config)
        raise ConfigurationError, "#{class_name} is not configured for dual writes"
      end

      replicate_to(operation.to_sym, klass, replica.to_sym, primary_key, attributes)
    end

    private

    def replicate_to(operation, klass, replica, primary_key, attributes)
      klass.connected_to(role: :writing, shard: replica) do
        klass.transaction do
          case operation
          when :create, :update
            klass.upsert(attributes.merge('id' => primary_key), unique_by: :id)
          when :destroy
            klass.where(id: primary_key).delete_all
          else
            raise ReplicationError, "unknown operation: #{operation}"
          end
        end
      end
    rescue ActiveRecord::ConnectionNotEstablished => e
      raise ReplicationError, "connection to #{replica} not established: #{e.message}"
    end
  end
end
