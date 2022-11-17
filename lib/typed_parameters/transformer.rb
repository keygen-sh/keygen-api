# frozen_string_literal: true

require_relative 'rule'

module TypedParameters
  class Transformer < Rule
    def call(params)
      depth_first_map(params) do |param|

      end
    end
  end
end
