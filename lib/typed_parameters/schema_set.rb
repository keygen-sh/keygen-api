# frozen_string_literal: true

require_relative 'hash_with_deep_access'

module TypedParameters
  class SchemaSet
    def initialize = @schemas = HashWithDeepAccess.new

    def include?(*keys) = @schemas.dig(*keys).present?

    delegate :[]=, :[], to: :@schemas
  end
end
