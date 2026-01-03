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
      def create(primary_key, attributes)
        replica_class.insert!(serialize(attributes).merge('id' => primary_key, 'is_deleted' => 0))
      end

      def update(primary_key, attributes)
        replica_class.insert!(serialize(attributes).merge('id' => primary_key, 'is_deleted' => 0))
      end

      def destroy(primary_key, attributes)
        # Insert a tombstone row with is_deleted = 1
        # ReplacingMergeTree(ver, is_deleted) will handle cleanup
        replica_class.insert!(serialize(attributes).merge('id' => primary_key, 'is_deleted' => 1))
      end

      def insert_all(records)
        serialized = records.map { |attrs| serialize(attrs).merge('is_deleted' => 0) }
        replica_class.insert_all!(serialized)
      end

      def upsert_all(records)
        # For ClickHouse, upsert becomes insert (ReplacingMergeTree handles dedup)
        insert_all(records)
      end

      private

      # Serialize complex values to JSON for ClickHouse compatibility.
      # ClickHouse expects JSON strings for complex types.
      def serialize(attributes)
        attributes.transform_values { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.to_json : v }
      end
    end
  end
end
