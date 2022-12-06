# frozen_string_literal: true

module TypedParameters
  class Format
    attr_reader :format

    def initialize(format, handler:)
      @format  = format
      @handler = handler
    end

    def call(...) = @handler.call(...)
  end
end
