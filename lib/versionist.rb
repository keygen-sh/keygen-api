# frozen_string_literal: true

module Versionist
  class InvalidVersion < StandardError; end

  CURRENT_VERSION = '1.1'

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end

  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:logger) { Rails.logger }
  end

  class Transform
    include Rails.application.routes.url_helpers

    mattr_accessor :__versionist_request_transformers,  default: []
    mattr_accessor :__versionist_response_transformers, default: []
    mattr_accessor :__versionist_routes,                default: []

    def initialize(version:, controller: nil, request: nil, response: nil)
      @version    = Semverse::Version.new(version.delete_prefix('v'))
      @controller = controller
      @request    = request
      @response   = response
    end

    def transform_request!
      return unless
        @request.present?

      __versionist_request_transformers.each do |transformer|
        instance_exec(@request, &transformer)
      rescue => e
        Versionist.config.logger.error(e)
      end
    end

    def transform_response!
      return unless
        @response.present?

      __versionist_response_transformers.each do |transformer|
        instance_exec(@response, &transformer)
      rescue => e
        Versionist.config.logger.error(e)
      end
    end

    def transforms_version?(version)
      version = Semverse::Version.coerce(version)

      version < @version
    end

    def transforms_route?(route)
      __versionist_routes.include?(route.to_sym)
    end

    private

    def self.request(&block)
      __versionist_request_transformers << block
    end

    def self.response(&block)
      __versionist_response_transformers << block
    end

    def self.route(route)
      __versionist_routes << route.to_sym
    end

    def self.routes(*routes)
      routes.each { |r| self.route(r) }
    end

    def self.description(...)= nil
  end

  module Transformer
    extend ActiveSupport::Concern

    # FIXME(ezekg) This should allow transforming multiple controllers
    def self.[](transforms)
      @transforms = transforms

      self
    end

    def self.transforms
      @transforms
    end

    included do
      around_action :transform!

      private

      def transform!
        validate_current_version!
        transform_request!

        yield

        transform_response!
      end

      def validate_current_version!
        Semverse::Version.coerce(current_version)
      rescue Semverse::InvalidVersionFormat
        raise InvalidVersion, 'invalid version string provided'
      end

      def transform_request!
        transforms.each do |version, transformers|
          transformers.each do |transformer|
            t = transformer.new(version: version, controller: self, request: request)
            next unless
              t.transforms_version?(current_version)

            next unless
              t.transforms_route?(current_route)

            t.transform_request!
          rescue => e
            Versionist.config.logger.error(e)
          end
        end
      end

      def transform_response!
        transforms.each do |version, transformers|
          transformers.each do |transformer|
            t = transformer.new(version: version, controller: self, response: response)
            next unless
              t.transforms_version?(current_version)

            next unless
              t.transforms_route?(current_route)

            t.transform_response!
          rescue => e
            Versionist.config.logger.error(e)
          end
        end
      end

      def transforms
        t = Transformer.transforms || []

        t.sort_by { |(v, _)| Semverse::Version.coerce(v.delete_prefix('v')) }
         .reverse
      end

      def current_version
        request.headers.fetch('Keygen-Version', CURRENT_VERSION)
                       .delete_prefix('v')
      end

      def current_route
        Rails.application.routes.router.recognize(request) do |route, matches, param|
          return route.name
        end
      end
    end
  end
end
