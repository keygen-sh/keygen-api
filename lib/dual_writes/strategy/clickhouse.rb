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
        replica_class.insert!(attributes.merge('is_deleted' => 0))
      end

      def update(attributes, performed_at:)
        replica_class.insert!(attributes.merge('is_deleted' => 0))
      end

      def destroy(attributes, performed_at:)
        # Insert a tombstone row with is_deleted = 1
        # ReplacingMergeTree(ver, is_deleted) will handle cleanup
        replica_class.insert!(attributes.merge('is_deleted' => 1))
      end

      def insert_all(records, performed_at:)
        prepared = records.map { |attrs| attrs.merge('is_deleted' => 0) }

        replica_class.insert_all!(prepared)
      end

      def upsert_all(records, performed_at:)
        # For ClickHouse, upsert becomes insert (ReplacingMergeTree handles dedup)
        insert_all(records, performed_at:)
      end

      def delete_all(relation, performed_at:)
        # Extract query components from the passed relation and rebuild on replica_class
        replica_relation = replica_class.all
        replica_relation = replica_relation.where(relation.where_values_hash) if relation.where_values_hash.present?
        replica_relation = replica_relation.order(relation.order_values) if relation.order_values.present?
        replica_relation = replica_relation.limit(relation.limit_value) if relation.limit_value
        replica_relation = replica_relation.offset(relation.offset_value) if relation.offset_value

        # Constrain to records created before the operation to handle out-of-order replication.
        # This prevents deleting records that were inserted after the delete_all was performed.
        replica_relation = replica_relation.where(replica_class.arel_table[:created_at].lteq(performed_at))

        # Use ClickHouse's lightweight delete
        replica_relation.delete_all
      end
    end
  end
end
