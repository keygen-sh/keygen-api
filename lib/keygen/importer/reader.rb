# frozen_string_literal: true

module Keygen
  module Importer
    class Reader
      def initialize(io) = @io = io
      def read(n)        = @io.read(n)
    end
  end
end
