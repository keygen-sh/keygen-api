# frozen_string_literal: true

require_relative 'transform'

module TypedParameters
  module Transforms
    class Noop < Transform
      def call(key, value) = []
    end
  end
end
