# frozen_string_literal: true

module TypedParameters
  module Transforms
    class Transform
      def call(key, value) = raise NotImplementedError

      # FIXME(ezekg) Is there a cleaner way of delegating arity?
      def arity = method(:call).arity
    end
  end
end
