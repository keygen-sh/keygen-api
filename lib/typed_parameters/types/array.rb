# frozen_string_literal: true

module TypedParameters
  module Types
    register(:array,
      accepts_block: true,
      scalar: false,
      coerce: -> v { v.is_a?(String) ? v.split(',') : Array(v) },
      match: -> v { v.is_a?(Array) },
    )
  end
end
