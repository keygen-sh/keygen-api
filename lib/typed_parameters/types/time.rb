# frozen_string_literal: true

module TypedParameters
  module Types
    register(:time,
      match: -> v { v.is_a?(Time) },
      coerce: -> v {
        return nil if
          v.blank?

        case
        when v.to_s.match?(/\A\d+\z/)
          Time.at(v.to_i)
        else
          v.to_time
        end
      },
    )
  end
end
