module Keygen
  module Error
    class UnauthorizedError < StandardError; end
    class InvalidScopeError < StandardError
      attr_reader :source

      def initialize(parameter:)
        @source = { parameter: parameter }
      end
    end
  end
end
