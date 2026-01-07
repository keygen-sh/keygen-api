# frozen_string_literal: true

module DualWrites
  # Base class for bulk replication operations.
  #
  # BulkOperations encapsulate both the record collection and the execution context
  # (like performed_at timestamp), separating actual parameters from internal state.
  #
  # Uses double dispatch to delegate execution to the appropriate strategy handler,
  # enabling clean polymorphic behavior without switch statements.
  #
  # @example
  #   operation = BulkOperation::InsertAll.new(records)
  #   strategy.execute(operation) # delegates to strategy.handle_insert_all(operation)
  #
  class BulkOperation
    class << self
      # Look up a bulk operation class by name.
      #
      # @param name [Symbol, String] the operation name (:insert_all, :upsert_all)
      # @return [Class] the operation class
      # @raise [ArgumentError] if the operation is not found
      def lookup(name)
        const_get("#{self.name}::#{name.to_s.camelize}")
      rescue NameError
        raise ArgumentError, "unknown bulk operation: #{name.inspect}"
      end
    end

    attr_reader :records,
                :performed_at

    # @param records [Array<Hash>] the records to operate on
    # @param performed_at [Time] when the operation was performed on the primary (default: now)
    def initialize(records, performed_at: Time.current)
      @records      = records
      @performed_at = performed_at
    end

    # Execute this operation with the given strategy.
    # Subclasses override to call the appropriate strategy handler.
    #
    # @param strategy [Strategy] the strategy to execute with
    # @raise [NotImplementedError] if not overridden by subclass
    def execute_with(strategy)
      raise NotImplementedError, "#{self.class}#execute_with must be implemented"
    end

    # Replicate a bulk insert operation.
    class InsertAll < BulkOperation
      def execute_with(strategy) = strategy.handle_insert_all(self)
    end

    # Replicate a bulk upsert operation.
    class UpsertAll < BulkOperation
      def execute_with(strategy) = strategy.handle_upsert_all(self)
    end
  end
end
