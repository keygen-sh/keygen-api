# frozen_string_literal: true

module TypedParameters
  class Path
    def initialize(*keys) = @keys = keys.flatten

    def <<(v) = @keys << v
    def keys  = @keys.dup
    def to_s  = @keys.join('/')
  end
end
