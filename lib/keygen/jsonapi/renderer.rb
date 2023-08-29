# frozen_string_literal: true

require 'jsonapi/serializable/renderer'

module Keygen::JSONAPI
  class Renderer < ::JSONAPI::Serializable::Renderer
    def initialize(account: nil, bearer: nil, token: nil, context: nil)
      @renderer = ::JSONAPI::Renderer.new
      @default_options = {
        class: -> klass { "#{klass}Serializer".safe_constantize },
        expose: {
          url_helpers: ::Rails.application.routes.url_helpers,
          context:,
          account:,
          bearer:,
          token:,
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
