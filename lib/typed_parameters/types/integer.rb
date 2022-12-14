# frozen_string_literal: true

module TypedParameters
  module Types
    register(:integer,
      coerce: -> v { v.blank? ? nil : v.to_i },
      match: -> v { v.is_a?(Integer) },
    )
  end
end
