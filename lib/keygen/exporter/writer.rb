# frozen_string_literal: true

require 'digest'

module Keygen
  module Exporter
    class Writer
      def initialize(io, digest: Digest::SHA256.new)
        raise ArgumentError, 'io object is required' unless writable?(io)

        @io = DigestIO.new(io, digest:)
      end

      def write(data)            = @io.write(data)
      def write_version(version) = write([version].pack('C')) # first byte is the version
      def write_chunk(data)      = raise NotImplementedError

      def to_io
        @io.tap { it.rewind if seekable?(it) }
      end

      private

      def writable?(io) = io.respond_to?(:write)
      def seekable?(io)
        if io.respond_to?(:stat)
          io.stat.file?
        else
          io.respond_to?(:seek)
        end
      end
    end
  end
end
