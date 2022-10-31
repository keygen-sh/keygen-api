# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      name: :null,
      type: :nil,
      coerce: -> v { nil },
      match: -> v { v.nil? },
    )
  end
end
