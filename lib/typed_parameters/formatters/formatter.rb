# frozen_string_literal: true

module TypedParameters
  class Formatter
    attr_reader :format

    def initialize(format, transform:)
      @format    = format
      @transform = transform
    end

    def call(...) = @transform.call(...)
  end
end
