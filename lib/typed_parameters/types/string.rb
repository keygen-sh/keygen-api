# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      type: :string,
      coerce: -> v { v.to_s },
      match: -> v { v.is_a?(String) },
    )
  end
end
