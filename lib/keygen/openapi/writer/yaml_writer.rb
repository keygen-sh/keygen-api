# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Keygen
  module OpenAPI
    module Writer
      class YamlWriter
        attr_reader :output_dir, :edition

        def initialize(output_dir, edition: :ce)
          @output_dir = Pathname.new(output_dir)
          @edition = edition
        end

        def write(spec)
          # Create directory structure
          create_directories

          # Write root spec file
          write_root_spec(spec[:root])

          # Write common schemas
          write_common_schemas(spec[:common_schemas])

          # Write paths
          write_paths(spec[:paths]) if spec[:paths]

          # Write schemas
          write_schemas(spec[:schemas]) if spec[:schemas]

          # Write parameters
          write_parameters(spec[:parameters]) if spec[:parameters]

          # Write responses
          write_responses(spec[:responses]) if spec[:responses]
        end

        private

        def create_directories
          [
            output_dir,
            output_dir.join('paths'),
            output_dir.join('schemas', 'requests'),
            output_dir.join('schemas', 'responses'),
            output_dir.join('schemas', 'objects'),
            output_dir.join('schemas', 'common'),
            output_dir.join('schemas', 'enums'),
            output_dir.join('parameters'),
            output_dir.join('responses')
          ].each do |dir|
            FileUtils.mkdir_p(dir)
          end
        end

        def write_root_spec(root_spec)
          filename = edition == :ce ? 'openapi.yaml' : 'openapi-ee.yaml'
          path = output_dir.join(filename)

          File.write(path, root_spec.to_yaml)
        end

        def write_common_schemas(schemas)
          return unless schemas

          schemas.each do |name, schema|
            path = output_dir.join('schemas', 'common', "#{name}.yaml")
            File.write(path, schema.to_yaml)
          end
        end

        def write_paths(paths)
          paths.each do |path_key, path_spec|
            filename = path_to_filename(path_key)
            path = output_dir.join('paths', filename)

            File.write(path, path_spec.to_yaml)
          end
        end

        def write_schemas(schemas)
          schemas.each do |category, category_schemas|
            category_schemas.each do |name, schema|
              path = output_dir.join('schemas', category.to_s, "#{name}.yaml")
              File.write(path, schema.to_yaml)
            end
          end
        end

        def write_parameters(parameters)
          parameters.each do |name, param_spec|
            path = output_dir.join('parameters', "#{name}.yaml")
            File.write(path, param_spec.to_yaml)
          end
        end

        def write_responses(responses)
          responses.each do |name, response_spec|
            path = output_dir.join('responses', "#{name}.yaml")
            File.write(path, response_spec.to_yaml)
          end
        end

        def path_to_filename(path)
          # /v1/accounts/{account_id}/licenses/{id}/actions/validate
          # => accounts_{account_id}_licenses_{id}_actions_validate.yaml

          # Handle root path /v1 specially
          return 'root.yaml' if path == '/v1'

          cleaned = path
            .gsub(%r{^/v1/}, '')
            .gsub(%r{/}, '_')
            .gsub(/[{}]/, '')

          # Handle empty result
          cleaned = 'root' if cleaned.empty?

          "#{cleaned}.yaml"
        end
      end
    end
  end
end
