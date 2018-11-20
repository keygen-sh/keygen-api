module Keygen
  module Error
    class UnauthorizedError < StandardError; end

    class InvalidScopeError < StandardError
      attr_reader :source

      def initialize(parameter:)
        @source = { parameter: parameter }
      end
    end

    class NotFoundError < ActiveRecord::RecordNotFound
      def initialize(message: nil, model: nil, primary_key: nil, id: nil)
        super message, model, primary_key, id
      end
    end
  end
end
