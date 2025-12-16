# frozen_string_literal: true

require_relative 'parser/route_parser'
require_relative 'parser/typed_params_parser'
require_relative 'parser/serializer_parser'
require_relative 'schema/parameter_schema_builder'
require_relative 'schema/request_body_builder'
require_relative 'schema/response_schema_builder'
require_relative 'schema/common_schemas'
require_relative 'version/version_resolver'
require_relative 'version/migration_tracker'
require_relative 'writer/yaml_writer'
require_relative 'writer/spec_builder'
require_relative 'writer/ref_resolver'
require_relative 'filters/ee_filter'
require_relative 'filters/version_filter'

module Keygen
  module OpenAPI
    class Generator
      SUPPORTED_VERSIONS = %w[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7].freeze

      attr_reader :output_dir, :logger

      def initialize(output_dir: 'openapi', logger: Rails.logger)
        @output_dir = Pathname.new(output_dir)
        @logger = logger
        @routes = []
        @controllers = {}
        @serializers = {}
        @schemas = {}
      end

      def generate(edition: :both)
        logger.info "Starting OpenAPI spec generation for edition: #{edition}"

        # Phase 1: Parse all sources
        parse_routes
        parse_controllers
        parse_serializers

        # Phase 2: Build schemas
        build_schemas

        # Phase 3: Write output
        case edition
        when :ce
          write_ce_spec
        when :ee
          write_ee_spec
        when :both
          write_ce_spec
          write_ee_spec
        end

        logger.info "OpenAPI spec generation completed"
      end

      private

      def parse_routes
        logger.info "Parsing routes..."
        parser = Parser::RouteParser.new
        @routes = parser.parse(Rails.application.routes.routes)
        logger.info "Found #{@routes.count} API routes"
      end

      def parse_controllers
        logger.info "Parsing controllers..."
        parser = Parser::TypedParamsParser.new

        controller_files = Dir.glob(Rails.root.join('app/controllers/api/v1/**/*_controller.rb'))

        controller_files.each do |file_path|
          begin
            controller_data = parser.parse_file(file_path)
            @controllers[controller_data[:name]] = controller_data
          rescue => e
            logger.warn "Failed to parse controller #{file_path}: #{e.message}"
          end
        end

        logger.info "Parsed #{@controllers.count} controllers"
      end

      def parse_serializers
        logger.info "Parsing serializers..."
        parser = Parser::SerializerParser.new

        serializer_files = Dir.glob(Rails.root.join('app/serializers/*_serializer.rb'))

        serializer_files.each do |file_path|
          begin
            serializer_data = parser.parse_file(file_path)
            @serializers[serializer_data[:name]] = serializer_data if serializer_data
          rescue => e
            logger.warn "Failed to parse serializer #{file_path}: #{e.message}"
          end
        end

        logger.info "Parsed #{@serializers.count} serializers"
      end

      def build_schemas
        logger.info "Building schemas..."
        # Schemas will be built during spec writing based on routes
        # This method can be expanded to pre-build common schemas
      end

      def write_ce_spec
        logger.info "Writing CE specification..."
        writer = Writer::YamlWriter.new(output_dir, edition: :ce)
        spec_builder = Writer::SpecBuilder.new(@routes, @controllers, @serializers, edition: :ce)

        spec = spec_builder.build
        writer.write(spec)
        logger.info "CE spec written to #{output_dir}/openapi.yaml"
      end

      def write_ee_spec
        logger.info "Writing EE specification..."
        writer = Writer::YamlWriter.new(output_dir, edition: :ee)
        spec_builder = Writer::SpecBuilder.new(@routes, @controllers, @serializers, edition: :ee)

        spec = spec_builder.build
        writer.write(spec)
        logger.info "EE spec written to #{output_dir}/openapi-ee.yaml"
      end
    end
  end
end
