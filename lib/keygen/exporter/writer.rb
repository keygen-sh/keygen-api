# frozen_string_literal: true

module Keygen
  module Exporter
    class Writer
      def initialize(io)         = @io = io
      def write(data)            = @io.write(data)
      def write_version(version) = write([version].pack('C')) # first byte is the version
      def write_chunk(data)      = raise NotImplementedError
      def to_io                  = @io.tap do |io|
        io.rewind if seekable?
      end

      private

      def seekable?
        if @io.respond_to?(:stat)
          @io.stat.file?
        else
          @io.respond_to?(:seek)
        end
      end
    end
  end
end
