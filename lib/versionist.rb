# frozen_string_literal: true

module Versionist
  class InvalidVersionFormatError < StandardError; end
  class UnsupportedVersionError < StandardError; end
  class InvalidVersionError < StandardError; end

  SUPPORTED_VERSION_FORMATS = %i[semver date float integer string].freeze
  TARGET_VERSION_METHOD     = :versionist_version

  def self.logger
    @logger ||= Versionist.config.logger.tagged(:versionist)
  end

  def self.supported_versions
    @supported_versions ||= [
      Versionist.config.current_version,
      *Versionist.config.versions.keys,
    ].uniq.freeze
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end

  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:logger)          { Rails.logger }
    config_accessor(:version_format)  { :semver }
    config_accessor(:current_version) { nil }
    config_accessor(:versions)        { [] }
  end

  class Migration
    class ConditionalBlock
      def initialize(if: nil, &block)
        @if    = binding.local_variable_get(:if)
        @block = block
      end

      def call(ctx, *args)
        return if
          @if.respond_to?(:call) && !@if.call(*args)

        ctx.instance_exec(*args, &@block)
      end
    end

    module DSL
      def self.extended(klass)
        class << klass
          attr_accessor :description_value,
                        :request_blocks,
                        :migration_blocks,
                        :response_blocks
        end

        klass.description_value = nil
        klass.request_blocks    = []
        klass.migration_blocks  = []
        klass.response_blocks   = []
      end

      def inherited(klass)
        klass.description_value = description_value.dup
        klass.request_blocks    = request_blocks.dup
        klass.migration_blocks  = migration_blocks.dup
        klass.response_blocks   = response_blocks.dup
      end

      def description(desc)
        self.description_value = desc
      end

      def request(if: nil, &block)
        self.request_blocks << ConditionalBlock.new(if:, &block)
      end

      def migrate(if: nil, &block)
        self.migration_blocks << ConditionalBlock.new(if:, &block)
      end

      def response(if: nil, &block)
        self.response_blocks << ConditionalBlock.new(if:, &block)
      end
    end

    include Rails.application.routes.url_helpers

    extend DSL

    def initialize = nil

    def migrate_request!(request)
      self.class.request_blocks.each { |b|
        instance_exec(request) { |r| b.call(self, r) }
      }
    end

    def migrate!(data)
      self.class.migration_blocks.each { |b|
        instance_exec(data) { |d| b.call(self, d) }
      }
    end

    def migrate_response!(response)
      self.class.response_blocks.each { |b|
        instance_exec(response) { |r| b.call(self, r) }
      }
    end
  end

  class Version
    include Comparable

    attr_reader :format,
                :value

    def initialize(version)
      raise UnsupportedVersionError, "version is unsupported: #{version}" unless
        version.in?(Versionist.supported_versions)

      @format = Versionist.config.version_format.to_sym
      @value  = case @format
                when :semver
                  Semverse::Version.coerce(version)
                when :date
                  Date.parse(version)
                when :integer
                  version.to_i
                when :float
                  version.to_f
                when :string
                  version.to_s
                else
                  raise InvalidVersionFormatError, "invalid version format: #{@format} (must be one of: #{SUPPORTED_VERSION_FORMATS.join(',')}"
                end
    rescue Semverse::InvalidVersionFormat,
           Date::Error
      raise InvalidVersionError, "invalid #{@format} version given: #{version}"
    end

    def <=>(other)
      @value <=> Version.coerce(other).value
    end

    def to_s
      @value.to_s
    end

    class << self
      def coerce(version)
        version.is_a?(self) ? version : new(version)
      end
    end
  end

  class Migrator
    def initialize(from:, to:)
      @current_version = Version.new(from)
      @target_version  = Version.new(to)
    end

    def migrate!(data:)
      logger.debug { "Migrating from #{current_version} to #{target_version} (#{migrations.size} potential migrations)" }

      migrations.each_with_index { |migration_name, i|
        logger.debug { "Applying migration #{migration_name} (#{i + 1}/#{migrations.size})" }

        klass     = migration_name.to_s.classify.constantize
        migration = klass.new

        migration.migrate!(data)
      }

      logger.debug { "Migrated from #{current_version} to #{target_version}" }
    end

    private

    attr_accessor :current_version,
                  :target_version

    # TODO(ezekg) These should be sorted
    def migrations
      @migrations ||= Versionist.config.versions
                                       .filter_map { |(version, migration_set)|
                                         migration_set_version = Version.new(version)

                                         migration_set if
                                           migration_set_version <= current_version &&
                                           migration_set_version > target_version
                                       }
                                       .flatten
    end

    def logger
      Versionist.logger
    end
  end

  module Controller
    class Migrator < Migrator
      def initialize(request:, response:, **kwargs)
        super(**kwargs)

        @request  = request
        @response = response
      end

      def migrate!
        logger.debug { "Migrating from #{current_version} to #{target_version} (#{migrations.size} potential migrations)" }

        migrations.each_with_index { |migration_name, i|
          logger.debug { "Applying migration #{migration_name} (#{i + 1}/#{migrations.size})" }

          klass     = migration_name.to_s.classify.constantize
          migration = klass.new

          migration.migrate_request!(request)
        }

        yield if
          block_given?

        migrations.each_with_index { |migration_name, i|
          logger.debug { "Applying migration #{migration_name} (#{i + 1}/#{migrations.size})" }

          klass     = migration_name.to_s.classify.constantize
          migration = klass.new

          migration.migrate_response!(response)
        }

        logger.debug { "Migrated from #{current_version} to #{target_version}" }
      end

      private

      attr_accessor :request,
                    :response

      def logger
        Versionist.logger.tagged(request&.request_id)
      end

      def router
        Rails.application.routes.router
      end

      def route
        router.recognize(request) { |r| return r.name }
      end
    end

    module Migrations
      extend ActiveSupport::Concern

      included do
        around_action :apply_migrations!

        private

        def apply_migrations!
          current_version = Versionist.config.current_version
          target_version  = send(TARGET_VERSION_METHOD)

          migrator = Migrator.new(from: current_version, to: target_version, request:, response:)
          migrator.migrate! { yield }
        end
      end
    end
  end
end
