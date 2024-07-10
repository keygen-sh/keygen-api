# frozen_string_literal: true

module Keygen
  module Exporter
    class Writer
      def initialize(io)         = @io = io
      def write(data)            = @io.write(data)
      def write_version(version) = write([version].pack('C')) # first byte is the version
      def write_chunk(data)      = raise NotImplementedError
      def to_io                  = @io.tap { _1.rewind if seekable? }

      private

      def seekable?
        return @seekable if defined?(@seekable)

        @seekable = @io.respond_to?(:seek) && !pipe?
      end

      def pipe?
        @io.pos
        false
      rescue Errno::EPIPE, Errno::ESPIPE
        true
      end
    end
  end
end
