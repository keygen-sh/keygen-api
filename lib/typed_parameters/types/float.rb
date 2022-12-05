# frozen_string_literal: true

module TypedParameters
  module Types
    register(:float,
      coerce: -> v { v.to_f },
      match: -> v { v.is_a?(Float) },
    )
  end
end
