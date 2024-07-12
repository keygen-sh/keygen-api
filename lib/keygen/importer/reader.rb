# frozen_string_literal: true

module Keygen
  module Importer
    class Reader
      def initialize(io)
        raise ArgumentError, 'io object is required' unless readable?(io)

        @io = io
      end

      def read(n) = @io.read(n)

      private

      def readable?(io) = io.respond_to?(:read)
    end
  end
end
