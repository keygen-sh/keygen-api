# frozen_string_literal: true

module TypedParameters
  module Validations
    class Validation
      def initialize(schema:) = @schema = schema

      def call = raise NotImplementedError

      private

      attr_reader :schema
    end
  end
end
