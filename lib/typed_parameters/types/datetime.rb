# frozen_string_literal: true

module TypedParameters
  module Types
    register(
      type: :datetime,
      coerce: -> v { v.to_s.match?(/\A\d+\z/) ? Time.at(v.to_i).to_datetime : v.to_datetime },
      match: -> v { v.is_a?(DateTime) },
    )
  end
end
