# frozen_string_literal: true

module Keygen
  module Import
    class Reader
      def initialize(io) = @io = io
      def read(n)        = @io.read(n)
      def read_version   = read(1).unpack1('C') # first byte is the version
      def read_chunk     = raise NotImplementedError
    end
  end
end
