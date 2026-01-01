# frozen_string_literal: true

module DualWrites
  class Strategy
    # ClickHouse replication strategy using ReplacingMergeTree.
    #
    # All operations become inserts:
    # - Creates and updates insert new rows with is_deleted = 0
    # - Deletes insert tombstone rows with is_deleted = 1
    #
    # ReplacingMergeTree(ver, is_deleted) handles deduplication and cleanup.
    #
    # @example Basic usage
    #   dual_writes to: :clickhouse, strategy: :clickhouse
    #
    # @example With TTL expiration
    #   dual_writes to: :clickhouse, strategy: :clickhouse,
    #     clickhouse_ttl: -> { account.request_log_retention_duration }
    #
    # Strategy-specific options (prefix with clickhouse_):
    # - clickhouse_ttl: Proc that returns TTL in seconds, evaluated per-record
    #
    class Clickhouse < Strategy
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
  end
end
