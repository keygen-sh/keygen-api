# frozen_string_literal: true

module DualWrites
  # Encapsulates execution context for replication operations.
  #
  # Context separates execution metadata from the actual data being replicated,
  # making the boundary between parameters and internal state explicit.
  #
  # @example Creating a context
  #   context = Context.new(performed_at: Time.current)
  #
  # @example Using with an operation
  #   context = Context.new(performed_at: Time.current)
  #   operation = Operation::Create.new(attributes, context:)
  #
  class Context
    attr_reader :performed_at

    # @param performed_at [Time] when the operation was performed on the primary (default: now)
    def initialize(performed_at: Time.current)
      @performed_at = performed_at
    end
  end
end
