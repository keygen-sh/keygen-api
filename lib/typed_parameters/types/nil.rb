# frozen_string_literal: true

module TypedParameters
  module Types
    register(:nil,
      name: :null,
      coerce: -> v { nil },
      match: -> v { v.nil? },
    )
  end
end
