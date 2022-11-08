# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      type: :date,
      coerce: -> v { v.to_date },
      match: -> v { v.is_a?(Date) },
    )
  end
end
