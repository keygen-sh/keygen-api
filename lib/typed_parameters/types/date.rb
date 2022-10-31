# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      type: :date,
      scalar: false,
      coerce: -> v { v.to_date },
      match: -> v { v.is_a?(Date) },
    )
  end
end
