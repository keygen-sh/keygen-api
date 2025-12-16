# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Keygen
  module OpenAPI
    module Writer
      class YamlWriter
        attr_reader :output_dir, :edition, :monolithic

        def initialize(output_dir, edition: :ce, monolithic: false)
          @output_dir = Pathname.new(output_dir)
          @edition = edition
          @monolithic = monolithic
        end

        def write(spec)
          if monolithic
            write_monolithic_spec(spec)
          else
            write_split_spec(spec)
          end
        end

        def write_monolithic_spec(spec)
          # Create output directory
          FileUtils.mkdir_p(output_dir)

          # Build complete monolithic spec
          complete_spec = build_monolithic_spec(spec)

          # Write single file
          filename = edition == :ce ? 'openapi-monolithic.yaml' : 'openapi-ee-monolithic.yaml'
          path = output_dir.join(filename)

          File.write(path, complete_spec.to_yaml)
        end

        def write_split_spec(spec)
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

        def build_monolithic_spec(spec)
          # Start with the root spec
          complete_spec = Marshal.load(Marshal.dump(spec[:root]))

          # Inline paths
          if spec[:paths]
            spec[:paths].each do |path_key, path_data|
              complete_spec['paths'][path_key] = path_data
            end
          end

          # Inline schemas into components
          if spec[:schemas]
            complete_spec['components'] ||= {}
            complete_spec['components']['schemas'] ||= {}

            spec[:schemas].each do |category, category_schemas|
              category_schemas.each do |name, schema|
                complete_spec['components']['schemas'][name] = schema
              end
            end
          end

          # Inline common schemas
          if spec[:common_schemas]
            complete_spec['components'] ||= {}
            complete_spec['components']['schemas'] ||= {}

            spec[:common_schemas].each do |name, schema|
              complete_spec['components']['schemas'][name] = schema
            end
          end

          # Inline parameters
          if spec[:parameters]
            complete_spec['components'] ||= {}
            complete_spec['components']['parameters'] ||= {}

            spec[:parameters].each do |name, param_spec|
              complete_spec['components']['parameters'][name] = param_spec
            end
          end

          # Inline responses
          if spec[:responses]
            complete_spec['components'] ||= {}
            complete_spec['components']['responses'] ||= {}

            spec[:responses].each do |name, response_spec|
              complete_spec['components']['responses'][name] = response_spec
            end
          end

          complete_spec
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
