# frozen_string_literal: true

module Versionist
  class InvalidVersionError < StandardError; end

  VERSION_METHOD = :versionist_version

  def self.logger
    Versionist.config.logger
  end

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
    def self.[](version)
      Class.new(VersionedMigration) { |c| c.version = version }
    end
  end

  class VersionedMigration
    def self.transform!(data)
      return unless
        data.present? && @migrations.any?

      @migrations.select(&:for_data?).each do |migration|
        instance_exec(data, &migration)
      rescue => e
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
      end
    end

    def self.migrate_request!(request)
      return unless
        request.present? && @migrations.any?

      @migrations.select(&:for_request?).each do |migration|
        instance_exec(request, &migration)
      rescue => e
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
      end
    end

    def self.migrate_response!(response)
      return unless
        response.present? && @migrations.any?

      @migrations.select(&:for_response?).each do |migration|
        instance_exec(response, &migration)
      rescue => e
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
      end
    end

    def self.migrate_version?(version)
      version = Semverse::Version.coerce(version)

      version < @@version
    end

    def self.migrate_route?(route)
      @routes.include?(route.to_sym)
    end

    private

    def self.version=(version)
      @@version = Semverse::Version.new(version.to_s.delete_prefix('v'))
    end

    def self.transform(&)
      @migrations ||= []
      @migrations << DataMigrationBlock.new(&)
    end

    def self.request(&)
      @migrations ||= []
      @migrations << RequestMigrationBlock.new(&)
    end

    def self.response(&)
      @migrations ||= []
      @migrations << ResponseMigrationBlock.new(&)
    end

    def self.route(route)
      @routes ||= []
      @routes << route.to_sym
    end

    def self.routes(*routes)
      routes.each { |r| route(r) }
    end

    def self.description(...)= nil

    def self.url_helpers
      Rails.application.routes.url_helpers
    end

    def self.logger
      Versionist.logger
    end
  end

  class AbstractMigrationBlock
    attr_reader :block

    def initialize(&block)
      @block = block
    end

    def call(...) = block.call(...)
    def to_proc   = block

    def for_data?     = false
    def for_request?  = false
    def for_response? = false
  end

  class DataMigrationBlock < AbstractMigrationBlock
    def for_data? = true
  end

  class RequestMigrationBlock < AbstractMigrationBlock
    def for_request? = true
  end

  class ResponseMigrationBlock < AbstractMigrationBlock
    def for_response? = true
  end

  module Migrations
    extend ActiveSupport::Concern

    def self.[](*migrations)
      @migrations = migrations

      self
    end

    def self.migrations
      @migrations
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
        Migrations.migrations.reverse.each do |migration|
          next unless
            migration.migrate_version?(current_version)

          next unless
            migration.migrate_route?(current_route)

          migration.migrate_request!(request)
        rescue => e
          Versionist.logger.error(e.message)
          Versionist.logger.error(e.backtrace.join("\n"))
        end
      end

      def migrate_response!
        Migrations.migrations.reverse.each do |migration|
          next unless
            migration.migrate_version?(current_version)

          next unless
            migration.migrate_route?(current_route)

          migration.migrate_response!(response)
        rescue => e
          Versionist.logger.error(e.message)
          Versionist.logger.error(e.backtrace.join("\n"))
        end
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
