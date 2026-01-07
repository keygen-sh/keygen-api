# frozen_string_literal: true

module DualWrites
  # Base class for single-record replication operations.
  #
  # Operations combine record attributes (the data parameter) with execution
  # context (internal metadata), making the boundary between them explicit.
  #
  # Uses double dispatch to delegate execution to the appropriate strategy handler,
  # enabling clean polymorphic behavior without switch statements.
  #
  # @example
  #   context = Context.new(performed_at: Time.current)
  #   operation = Operation::Create.new(attributes, context:)
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

    attr_reader :attributes, :context

    # @param attributes [Hash] the record attributes (includes primary key)
    # @param context [Context] the execution context
    def initialize(attributes, context:)
      @attributes = attributes
      @context    = context
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
