# frozen_string_literal: true

module TypedParameters
  class Path
    attr_reader :keys

    def initialize(*keys) = @keys = keys

    def to_json_pointer = '/' + keys.join('/')
    def to_dot_notation = keys.join('.')
  end
end
