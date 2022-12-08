# frozen_string_literal: true

require_relative 'typed_parameters/bouncer'
require_relative 'typed_parameters/coercer'
require_relative 'typed_parameters/controller'
require_relative 'typed_parameters/formatters'
require_relative 'typed_parameters/formatters/formatter'
require_relative 'typed_parameters/formatters/jsonapi'
require_relative 'typed_parameters/formatters/rails'
require_relative 'typed_parameters/parameter'
require_relative 'typed_parameters/parameterizer'
require_relative 'typed_parameters/path'
require_relative 'typed_parameters/pipeline'
require_relative 'typed_parameters/processor'
require_relative 'typed_parameters/rule'
require_relative 'typed_parameters/schema'
require_relative 'typed_parameters/transforms/nilify_blanks'
require_relative 'typed_parameters/transforms/noop'
require_relative 'typed_parameters/transforms/transform'
require_relative 'typed_parameters/transformer'
require_relative 'typed_parameters/types'
require_relative 'typed_parameters/types/array'
require_relative 'typed_parameters/types/boolean'
require_relative 'typed_parameters/types/date'
require_relative 'typed_parameters/types/decimal'
require_relative 'typed_parameters/types/float'
require_relative 'typed_parameters/types/hash'
require_relative 'typed_parameters/types/integer'
require_relative 'typed_parameters/types/nil'
require_relative 'typed_parameters/types/number'
require_relative 'typed_parameters/types/string'
require_relative 'typed_parameters/types/symbol'
require_relative 'typed_parameters/types/time'
require_relative 'typed_parameters/types/type'
require_relative 'typed_parameters/validations/exclusion'
require_relative 'typed_parameters/validations/format'
require_relative 'typed_parameters/validations/inclusion'
require_relative 'typed_parameters/validations/length'
require_relative 'typed_parameters/validations/validation'
require_relative 'typed_parameters/validator'

module TypedParameters
  # Sentinel value for determining if something should be automatic.
  # For example, automatically detecting a param's format via its
  # schema vs using an explicitly provided format.
  AUTO = Object.new

  # Sentinel value for determining if something is the root. For
  # example, determining if a schema is the root node.
  ROOT = Object.new

  class UnsupportedCoercionError < StandardError; end
  class FailedCoercionError < StandardError; end
  class UndefinedActionError < StandardError; end
  class InvalidMethodError < StandardError; end
  class DuplicateFormatterError < StandardError; end
  class DuplicateTypeError < StandardError; end

  class InvalidParameterError < StandardError
    attr_reader :path

    def initialize(message, path:)
      @path = path

      super(message)
    end

    def inspect
      "#<TypedParameters::InvalidParameterError message=#{message.inspect} path=#{path.inspect}>"
    end
  end

  class UnpermittedParameterError < InvalidParameterError; end

  def self.formats = Formatters
  def self.types   = Types
end
