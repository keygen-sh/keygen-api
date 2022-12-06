# frozen_string_literal: true

require_relative './formats/format'

module TypedParameters
  module Formats
    cattr_reader :formats, default: {}

    def self.register(format, handler:)
      raise DuplicateFormatError, 'format is already registered' if
        formats.key?(format)

      formats[format] = Format.new(format, handler:)
    end

    def self.unregister(type) = formats.delete(type)

    def self.[](format) = formats[format] || raise(ArgumentError, "invalid format: #{format.inspect}")
  end
end
