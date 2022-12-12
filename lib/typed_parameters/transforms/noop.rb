# frozen_string_literal: true

require_relative 'transform'

module TypedParameters
  module Transforms
    class Noop < Transform
      def call(*) = []
    end
  end
end
