# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      type: :integer,
      coerce: -> v { v.to_i },
      match: -> v { v.is_a?(Integer) },
    )
  end
end
