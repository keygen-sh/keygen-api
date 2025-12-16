# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Schema
      class RequestBodyBuilder
        def initialize(param_builder: ParameterSchemaBuilder.new)
          @param_builder = param_builder
        end

        # Build JSONAPI request body from typed_params
        def build(typed_params_data, resource_type:, operation:)
          return nil unless typed_params_data
          return nil unless typed_params_data[:format] == :jsonapi

          # Combine params from main block, ee_blocks, and with_blocks
          all_params = combine_all_params(typed_params_data)

          data_param = find_data_param(all_params)
          return nil unless data_param

          {
            'content' => {
              'application/vnd.api+json' => {
                'schema' => build_jsonapi_schema(data_param, resource_type, operation)
              }
            },
            'required' => true
          }
        end

        private

        def combine_all_params(typed_params_data)
          params = typed_params_data[:params] || []

          # Add params from EE blocks
          (typed_params_data[:ee_blocks] || []).each do |ee_block|
            params += ee_block[:params] if ee_block[:params]
          end

          # Add params from with blocks
          (typed_params_data[:with_blocks] || []).each do |with_block|
            params += with_block[:params] if with_block[:params]
          end

          params
        end

        def find_data_param(params)
          params.find { |p| p[:name] == 'data' || p[:name] == :data }
        end

        def build_jsonapi_schema(data_param, resource_type, operation)
          schema = {
            'type' => 'object',
            'required' => ['data'],
            'properties' => {
              'data' => build_data_schema(data_param, resource_type, operation)
            }
          }

          schema
        end

        def build_data_schema(data_param, resource_type, operation)
          nested_params = data_param[:nested_params] || []

          type_param = nested_params.find { |p| p[:name] == 'type' || p[:name] == :type }
          id_param = nested_params.find { |p| p[:name] == 'id' || p[:name] == :id }
          attributes_param = nested_params.find { |p| p[:name] == 'attributes' || p[:name] == :attributes }
          relationships_param = nested_params.find { |p| p[:name] == 'relationships' || p[:name] == :relationships }

          schema = {
            'type' => 'object',
            'properties' => {}
          }

          required_fields = ['type']

          # Type field
          if type_param
            schema['properties']['type'] = @param_builder.build(type_param)
          else
            schema['properties']['type'] = {
              'type' => 'string',
              'enum' => [resource_type, resource_type.singularize].uniq
            }
          end

          # ID field (required for update, optional/ignored for create)
          if id_param && !id_param[:optional]
            required_fields << 'id'
            schema['properties']['id'] = @param_builder.build(id_param)
          elsif id_param && id_param[:noop]
            schema['properties']['id'] = {
              'type' => 'string',
              'description' => 'Resource ID (ignored in request body, use path parameter)'
            }
          end

          # Attributes
          if attributes_param
            schema['properties']['attributes'] = @param_builder.build(attributes_param)
            required_fields << 'attributes' unless attributes_param[:optional]
          end

          # Relationships
          if relationships_param
            schema['properties']['relationships'] = @param_builder.build(relationships_param)
            required_fields << 'relationships' unless relationships_param[:optional]
          end

          schema['required'] = required_fields

          schema
        end
      end
    end
  end
end
