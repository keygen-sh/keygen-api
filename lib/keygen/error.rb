# frozen_string_literal: true

module Keygen
  module Error
    class UnauthorizedError < StandardError
      attr_reader :code

      def initialize(code:)
        @code = code
      end
    end

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

    class BadRequestError < StandardError; end
  end
end
