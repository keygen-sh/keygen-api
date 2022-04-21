# frozen_string_literal: true

module Versionist
  class InvalidVersionError < StandardError; end

  VERSION_METHOD = :versionist_version

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end

  class Configuration
    include ActiveSupport::Configurable

    # TODO(ezekg) Add support for version format, e.g. semver, date, etc.

    config_accessor(:logger) { Rails.logger }
  end

  class Migration
    include Rails.application.routes.url_helpers

    mattr_accessor :__versionist_request_migrations,  default: []
    mattr_accessor :__versionist_response_migrations, default: []
    mattr_accessor :__versionist_routes,                default: []

    def initialize(version:, controller: nil, request: nil, response: nil)
      @version    = Semverse::Version.new(version.delete_prefix('v'))
      @controller = controller
      @request    = request
      @response   = response
    end

    def migrate_request!
      return unless
        @request.present?

      __versionist_request_migrations.each do |migration|
        instance_exec(@request, &migration)
      rescue => e
        Versionist.config.logger.error(e)
      end
    end

    def migrate_response!
      return unless
        @response.present?

      __versionist_response_migrations.each do |migration|
        instance_exec(@response, &migration)
      rescue => e
        Versionist.config.logger.error(e)
      end
    end

    def migration_version?(version)
      version = Semverse::Version.coerce(version)

      version < @version
    end

    def migration_route?(route)
      __versionist_routes.include?(route.to_sym)
    end

    private

    def self.request(&block)
      __versionist_request_migrations << block
    end

    def self.response(&block)
      __versionist_response_migrations << block
    end

    def self.route(route)
      __versionist_routes << route.to_sym
    end

    def self.routes(*routes)
      routes.each { |r| self.route(r) }
    end

    def self.description(...)= nil
  end

  module Migrations
    extend ActiveSupport::Concern

    # FIXME(ezekg) This should allow migrating multiple controllers
    def self.[](migration)
      @migration = migration

      self
    end

    def self.migration
      @migration
    end

    included do
      around_action :migrate!

      private

      def migrate!
        validate_current_version!
        migrate_request!

        yield

        migrate_response!
      end

      def validate_current_version!
        Semverse::Version.coerce(current_version)
      rescue Semverse::InvalidVersionFormat
        raise InvalidVersionError, 'invalid version format'
      end

      def migrate_request!
        migration.each do |version, migrations|
          migrations.each do |migration|
            t = migration.new(version: version, controller: self, request: request)
            next unless
              t.migration_version?(current_version)

            next unless
              t.migration_route?(current_route)

            t.migrate_request!
          rescue => e
            Versionist.config.logger.error(e)
          end
        end
      end

      def migrate_response!
        migration.each do |version, migrations|
          migrations.each do |migration|
            t = migration.new(version: version, controller: self, response: response)
            next unless
              t.migration_version?(current_version)

            next unless
              t.migration_route?(current_route)

            t.migrate_response!
          rescue => e
            Versionist.config.logger.error(e)
          end
        end
      end

      def migration
        t = Migrations.migration || []

        t.sort_by { |(v, _)| Semverse::Version.coerce(v.delete_prefix('v')) }
         .reverse
      end

      def current_version
        send(VERSION_METHOD)
      end

      def current_route
        Rails.application.routes.router.recognize(request) do |route, matches, param|
          return route.name
        end
      end
    end
  end
end
