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
        replica_class.insert!(attributes.merge('id' => primary_key, 'is_deleted' => 0))
      end

      def update(primary_key, attributes)
        replica_class.insert!(attributes.merge('id' => primary_key, 'is_deleted' => 0))
      end

      def destroy(primary_key, attributes)
        # Insert a tombstone row with is_deleted = 1
        # ReplacingMergeTree(ver, is_deleted) will handle cleanup
        replica_class.insert!(attributes.merge('id' => primary_key, 'is_deleted' => 1))
      end

      def insert_all(records)
        prepared = records.map { |attrs| attrs.merge('is_deleted' => 0) }
        replica_class.insert_all!(prepared)
      end

      def upsert_all(records)
        # For ClickHouse, upsert becomes insert (ReplacingMergeTree handles dedup)
        insert_all(records)
      end

      def delete_all(query)
        where  = query[:where] || query['where']
        order  = query[:order] || query['order']
        limit  = query[:limit] || query['limit']
        offset = query[:offset] || query['offset']

        # Use TRUNCATE for unconditional deletes (much faster than DELETE)
        if where.blank? && order.blank? && limit.nil? && offset.nil?
          replica_class.connection.execute("TRUNCATE TABLE #{replica_class.table_name}")
          return
        end

        # Build relation from query params for conditional deletes
        relation = replica_class.all
        relation = relation.where(where) if where.present?
        relation = relation.order(Arel.sql(order.join(', '))) if order.present?
        relation = relation.limit(limit) if limit
        relation = relation.offset(offset) if offset

        # Use ClickHouse's lightweight delete
        relation.delete_all
      end
    end
  end
end
