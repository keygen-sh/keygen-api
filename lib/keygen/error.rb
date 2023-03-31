# frozen_string_literal: true

module Keygen
  module Error
    class UnauthorizedError < StandardError
      attr_reader :code,
                  :detail,
                  :source

      def initialize(message = 'is unauthorized', code:, detail: nil, parameter: nil, pointer: nil, header: nil)
        @code   = code
        @detail = detail
        @source = { parameter:, pointer:, header: }.compact

        super(message)
      end
    end

    class ForbiddenError < StandardError
      attr_reader :code,
                  :detail,
                  :source

      def initialize(message = 'is forbidden', code:, detail: nil, parameter: nil, pointer: nil, header: nil)
        @code   = code
        @detail = detail
        @source = { parameter:, pointer:, header: }.compact

        super(message)
      end
    end

    class InvalidParameterError < StandardError
      attr_reader :source

      def initialize(message = 'is invalid', parameter:)
        @source = { parameter: }

        super(message)
      end
    end

    class UnsupportedParameterError < InvalidParameterError
      def initialize(message = 'is unsupported', **) = super(message, **)
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
