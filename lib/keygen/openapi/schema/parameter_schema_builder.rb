# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Schema
      class ParameterSchemaBuilder
        TYPE_MAPPING = {
          string: 'string',
          integer: 'integer',
          boolean: 'boolean',
          hash: 'object',
          array: 'array',
          uuid: 'string',
          time: 'string'
        }.freeze

        FORMAT_MAPPING = {
          uuid: 'uuid',
          time: 'date-time'
        }.freeze

        # Build OpenAPI parameter schema from typed_params data
        def build(param_data, context: {})
          schema = {
            'type' => TYPE_MAPPING[param_data[:type]] || 'string'
          }

          # Add format if applicable
          if FORMAT_MAPPING.key?(param_data[:type])
            schema['format'] = FORMAT_MAPPING[param_data[:type]]
          end

          # Add description
          desc = generate_description(param_data)
          schema['description'] = desc if desc && !desc.empty?

          # Handle nullable
          if param_data[:allow_nil]
            schema['nullable'] = true
          end

          # Handle enums (inclusion validation)
          if param_data[:inclusion]
            enum_values = extract_enum_values(param_data[:inclusion])
            schema['enum'] = enum_values if enum_values.any?
          end

          # Handle nested objects (hash type)
          if param_data[:type] == :hash && param_data[:nested_params]&.any?
            schema['properties'] = {}
            required = []

            param_data[:nested_params].each do |nested_param|
              property_name = camelize_key(nested_param[:name])
              schema['properties'][property_name] = build(nested_param, context: context)

              unless nested_param[:optional]
                required << property_name
              end
            end

            schema['required'] = required if required.any?
          end

          # Handle arrays
          if param_data[:type] == :array
            if param_data[:nested_params]&.any?
              # Array of objects
              schema['items'] = {
                'type' => 'object',
                'properties' => {}
              }

              param_data[:nested_params].each do |nested_param|
                property_name = camelize_key(nested_param[:name])
                schema['items']['properties'][property_name] = build(nested_param, context: context)
              end
            else
              # Simple array
              schema['items'] = { 'type' => 'string' }
            end
          end

          # Add constraints
          add_constraints(schema, param_data)

          # Add EE marker
          if param_data[:ee_only]
            schema['x-enterprise'] = true
          end

          schema
        end

        private

        def generate_description(param_data)
          parts = []

          parts << "Optional parameter" if param_data[:optional]
          parts << "Can be null" if param_data[:allow_nil]
          parts << "Can be blank" if param_data[:allow_blank]

          if param_data[:inclusion]
            values = extract_enum_values(param_data[:inclusion])
            parts << "Allowed values: #{values.join(', ')}" if values.any?
          end

          if param_data[:noop]
            parts << "This parameter is ignored by the server"
          end

          parts.join('. ')
        end

        def extract_enum_values(inclusion_config)
          # inclusion can be:
          # { in: ['value1', 'value2'] }
          # or just ['value1', 'value2']

          if inclusion_config.is_a?(Hash)
            values = inclusion_config[:in] || inclusion_config['in']
            values.is_a?(Array) ? values : []
          elsif inclusion_config.is_a?(Array)
            inclusion_config
          else
            []
          end
        end

        def add_constraints(schema, param_data)
          # Add depth constraint for metadata hashes
          if param_data[:depth]
            max_depth = param_data[:depth][:maximum] || param_data[:depth]['maximum']
            schema['x-max-depth'] = max_depth if max_depth
          end

          # Add custom extensions for typed_params-specific features
          if param_data[:transform]
            schema['x-transformed'] = true
          end

          if param_data[:as]
            schema['x-alias'] = param_data[:as].to_s
          end

          if param_data[:polymorphic]
            schema['x-polymorphic'] = true
          end
        end

        def camelize_key(key)
          # Convert snake_case to lowerCamelCase (matching TypedParams config)
          key.to_s.camelize(:lower)
        end
      end
    end
  end
end
