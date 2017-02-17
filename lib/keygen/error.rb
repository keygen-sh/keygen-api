module Keygen
  module Error
    class InvalidScopeError < StandardError;
      attr_reader :source

      def initialize(parameter:)
        @source = { parameter: parameter }
      end
    end
  end
end
