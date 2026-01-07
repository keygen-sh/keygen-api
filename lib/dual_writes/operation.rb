# frozen_string_literal: true

module DualWrites
  # Base class for single-record replication operations.
  #
  # Operations encapsulate both the record attributes and the execution context
  # (like performed_at timestamp), separating actual parameters from internal state.
  #
  # Uses double dispatch to delegate execution to the appropriate strategy handler,
  # enabling clean polymorphic behavior without switch statements.
  #
  # @example
  #   operation = Operation::Create.new(attributes)
  #   strategy.execute(operation) # delegates to strategy.handle_create(operation)
  #
  class Operation
    class << self
      # Look up an operation class by name.
      #
      # @param name [Symbol, String] the operation name (:create, :update, :destroy)
      # @return [Class] the operation class
      # @raise [ArgumentError] if the operation is not found
      def lookup(name)
        const_get("#{self.name}::#{name.to_s.camelize}")
      rescue NameError
        raise ArgumentError, "unknown operation: #{name.inspect}"
      end
    end

    attr_reader :attributes,
                :performed_at

    # @param attributes [Hash] the record attributes (includes primary key)
    # @param performed_at [Time] when the operation was performed on the primary (default: now)
    def initialize(attributes, performed_at: Time.current)
      @attributes   = attributes
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

    # Replicate a create operation.
    class Create < Operation
      def execute_with(strategy) = strategy.handle_create(self)
    end

    # Replicate an update operation.
    class Update < Operation
      def execute_with(strategy) = strategy.handle_update(self)
    end

    # Replicate a destroy operation.
    class Destroy < Operation
      def execute_with(strategy) = strategy.handle_destroy(self)
    end
  end
end
