# frozen_string_literal: true

require_relative 'formatter'

module TypedParameters
  module Formatters
    ##
    # The Rails formatter wraps the params in a key matching the current
    # controller's name.
    #
    # For example, in a UsersController context, given the params:
    #
    #   { email: 'foo@bar.example' }
    #
    # The final params would become:
    #
    #   { user: { email: 'foo@bar.example' } }
    #
    module Rails
      def self.call(params, controller:)
        key = controller.controller_name.singularize.to_sym

        { key => params }
      end
    end

    register(:rails,
      transform: Rails.method(:call),
    )
  end
end
