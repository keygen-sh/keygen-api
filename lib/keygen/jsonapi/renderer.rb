# frozen_string_literal: true

require 'jsonapi/serializable/renderer'

module Keygen::JSONAPI
  class Renderer < ::JSONAPI::Serializable::Renderer
    def initialize(account: nil, bearer: nil, token: nil, context: nil, api_version: nil)
      @renderer        = ::JSONAPI::Renderer.new
      @api_version     = api_version
      @account         = account
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
      data = super(resources, { **default_options, **options })

      # Migrate dataset to target API version
      migrate!(data:)

      data
    end

    private

    attr_reader :default_options,
                :api_version,
                :account

    def migrate!(data:)
      current_version = CURRENT_API_VERSION
      target_version  = api_version || account&.api_version
      return if
        current_version.nil? || target_version.nil?

      migrator = RequestMigrations::Migrator.new(
        from: current_version,
        to: target_version,
      )

      migrator.migrate!(data:)
    end
  end
end
