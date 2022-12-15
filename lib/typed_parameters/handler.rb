# frozen_string_literal: true

module TypedParameters
  class Handler
    attr_reader :for,
                :action,
                :schema,
                :format

    def initialize(for:, schema:, action: nil, format: nil)
      @for    = binding.local_variable_get(:for)
      @schema = schema
      @action = action
      @format = format
    end

    def action=(action)
      raise ArgumentError, 'cannot redefine action' if
        @action.present?

      @action = action
    end
  end
end
