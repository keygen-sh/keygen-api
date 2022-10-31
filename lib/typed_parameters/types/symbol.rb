# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      type: :symbol,
      coerce: -> v { v.to_sym },
      match: -> v { v.is_a?(Symbol) },
    )
  end
end
