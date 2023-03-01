# frozen_string_literal: true

module Keygen
  module Error
    class UnauthorizedError < StandardError
      attr_reader :code
      attr_reader :detail

      def initialize(code:, detail: nil)
        @code   = code
        @detail = detail
      end
    end

    class ForbiddenError < StandardError
      attr_reader :code
      attr_reader :detail

      def initialize(code:, detail: nil)
        @code   = code
        @detail = detail
      end
    end

    class InvalidScopeError < StandardError
      attr_reader :source

      def initialize(parameter:)
        @source = { parameter: }
      end
    end

    class InvalidHeaderError < StandardError
      attr_reader :source

      def initialize(message = 'is invalid', header:)
        @source = { header: }

        super(message)
      end
    end

    class UnsupportedHeaderError < InvalidHeaderError
      def initialize(message = 'is unsupported', **) = super(message, **)
    end

    class NotFoundError < ActiveRecord::RecordNotFound
      def initialize(message: nil, model: nil, primary_key: nil, id: nil)
        super message, model, primary_key, id
      end
    end

    class InvalidAccountDomainError < StandardError; end
    class InvalidAccountIdError < StandardError; end
    class InvalidEnvironmentError < StandardError; end
    class BadRequestError < StandardError; end
  end
end
