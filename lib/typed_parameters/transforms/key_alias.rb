# frozen_string_literal: true

require_relative 'transform'

module TypedParameters
  module Transforms
    class KeyAlias < Transform
      def initialize(as)   = @as = as
      def call(key, value) = [as, value]

      private

      attr_reader :as
    end
  end
end
