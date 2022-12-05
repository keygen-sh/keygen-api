# frozen_string_literal: true

module TypedParameters
  module Types
    register(:number,
      coerce: -> v { v.to_i },
      match: -> v { v.is_a?(Numeric) },
    )
  end
end
