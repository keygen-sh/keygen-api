# frozen_string_literal: true

module TypedParameters
  module Types
    register(:float,
      coerce: -> v { v.blank? ? nil : v.to_f },
      match: -> v { v.is_a?(Float) },
    )
  end
end
