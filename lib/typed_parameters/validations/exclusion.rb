# frozen_string_literal: true

require_relative 'inclusion'

module TypedParameters
  module Validations
    class Exclusion < Inclusion
      def call(*) = !super
    end
  end
end
