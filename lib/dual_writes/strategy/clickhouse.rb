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
    # @example
    #   dual_writes to: :clickhouse, strategy: :clickhouse
    #
    class Clickhouse < Strategy
      def create(attributes, performed_at:)
        replica_class.insert!(with_metadata(attributes, is_deleted: 0, ver: performed_at))
      end

      def update(attributes, performed_at:)
        replica_class.insert!(with_metadata(attributes, is_deleted: 0, ver: performed_at))
      end

      def destroy(attributes, performed_at:)
        # Insert a tombstone row with is_deleted = 1
        # ReplacingMergeTree(ver, is_deleted) will handle cleanup
        replica_class.insert!(with_metadata(attributes, is_deleted: 1, ver: performed_at))
      end

      def insert_all(attributes, performed_at:)
        attributes = attributes.map { with_metadata(it, is_deleted: 0, ver: performed_at) }

        replica_class.insert_all!(attributes)
      end

      def upsert_all(attributes, performed_at:)
        # For ClickHouse, upsert becomes insert (ReplacingMergeTree handles dedup)
        insert_all(attributes, performed_at:)
      end

      private

      def with_metadata(attributes, is_deleted:, ver:)
        attrs = attributes.dup
        attrs['is_deleted'] = is_deleted if replica_class.column_names.include?('is_deleted')
        attrs['ver'] = ver if replica_class.column_names.include?('ver')
        attrs
      end
    end
  end
end
