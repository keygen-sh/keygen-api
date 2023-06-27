# frozen_string_literal: true

module Keygen
  module Error
    class JSONAPIError < StandardError
      attr_reader :code,
                  :detail,
                  :source

      def initialize(message, code: nil, detail: nil, parameter: nil, pointer: nil, header: nil)
        @code   = code
        @detail = detail
        @source = { parameter:, pointer:, header: }.compact

        super(message)
      end
    end

    class UnauthorizedError < JSONAPIError
      def initialize(message = 'is unauthorized', code:, **) = super(message, **)
    end

    class ForbiddenError < JSONAPIError
      def initialize(message = 'is forbidden', code:, **) = super(message, **)
    end

    class InvalidParameterError < JSONAPIError
      def initialize(message = 'is invalid', parameter:, code: nil)
        super(message, parameter:, code:)
      end
    end

    class UnsupportedParameterError < InvalidParameterError
      def initialize(message = 'is unsupported', **) = super(message, **)
    end

    class InvalidHeaderError < JSONAPIError
      def initialize(message = 'is invalid', header:, code: nil)
        super(message, header:, code:)
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
