# frozen_string_literal: true

require 'jsonapi/serializable/renderer'

module Keygen
  module JSONAPI
    class Renderer < ::JSONAPI::Serializable::Renderer
      def initialize(context: nil)
        @renderer = ::JSONAPI::Renderer.new
        @default_options = {
          class: -> klass { "#{klass}Serializer".safe_constantize },
          expose: {
            url_helpers: ::Rails.application.routes.url_helpers,
            context: context&.to_sym,
          }
        }
      end

      def render(resources, options = {})
        super(resources, default_options.merge(options || {}))
      end

      private

      attr_reader :default_options
    end
  end
end
