# frozen_string_literal: true

namespace :keygen do
  namespace :openapi do
    desc 'Generate OpenAPI specifications for all API versions'
    task generate: :environment do
      require_relative '../../keygen/openapi/generator'

      output_dir = ENV.fetch('OUTPUT_DIR', 'openapi')
      edition = ENV.fetch('EDITION', 'both').to_sym # :ce, :ee, :both

      generator = Keygen::OpenAPI::Generator.new(
        output_dir: output_dir,
        logger: Keygen.logger
      )

      generator.generate(edition: edition)

      Keygen.logger.info "OpenAPI specs written to #{output_dir}/"
    rescue => e
      Keygen.logger.error "Failed to generate OpenAPI specs: #{e.message}"
      Keygen.logger.error e.backtrace.join("\n")
      exit 1
    end

    desc 'Validate generated OpenAPI specifications'
    task validate: :environment do
      require 'json'
      require 'yaml'

      output_dir = ENV.fetch('OUTPUT_DIR', 'openapi')

      %w[openapi.yaml openapi-ee.yaml].each do |spec_file|
        spec_path = File.join(output_dir, spec_file)
        next unless File.exist?(spec_path)

        Keygen.logger.info "Validating #{spec_file}..."

        begin
          spec = YAML.load_file(spec_path)

          # Basic validation
          raise "Missing openapi version" unless spec['openapi']
          raise "Missing info section" unless spec['info']
          raise "Missing paths section" unless spec['paths']

          Keygen.logger.info "✓ #{spec_file} is valid"
        rescue => e
          Keygen.logger.error "✗ #{spec_file} validation failed: #{e.message}"
          exit 1
        end
      end

      Keygen.logger.info "All specs validated successfully"
    end

    desc 'Clean generated OpenAPI files'
    task clean: :environment do
      output_dir = ENV.fetch('OUTPUT_DIR', 'openapi')

      if Dir.exist?(output_dir)
        Keygen.logger.info "Removing #{output_dir}/"
        FileUtils.rm_rf(output_dir)
        Keygen.logger.info "Done"
      else
        Keygen.logger.info "Nothing to clean"
      end
    end
  end
end
