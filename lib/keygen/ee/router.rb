# frozen_string_literal: true

module Keygen
  module EE
    module Router
      class Constraint
        def matches?(request) = Keygen.ee?
      end

      def ee(&)
        constraints Constraint.new do
          instance_eval(&)
        end
      end
    end
  end
end
