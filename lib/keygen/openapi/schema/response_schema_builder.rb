# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Schema
      class ResponseSchemaBuilder
        def initialize(edition: :ce)
          @edition = edition
        end

        # Build OpenAPI response schema from serializer data
        def build(serializer_data, collection: false)
          {
            'content' => {
              'application/vnd.api+json' => {
                'schema' => build_jsonapi_response_schema(serializer_data, collection)
              }
            }
          }
        end

        private

        def build_jsonapi_response_schema(serializer_data, collection)
          if collection
            {
              'allOf' => [
                { '$ref' => '#/components/schemas/JsonApiDocument' },
                {
                  'type' => 'object',
                  'properties' => {
                    'data' => {
                      'type' => 'array',
                      'items' => build_resource_identifier(serializer_data)
                    },
                    'meta' => {
                      '$ref' => '#/components/schemas/Pagination'
                    }
                  }
                }
              ]
            }
          else
            {
              'allOf' => [
                { '$ref' => '#/components/schemas/JsonApiDocument' },
                {
                  'type' => 'object',
                  'properties' => {
                    'data' => build_resource_identifier(serializer_data)
                  }
                }
              ]
            }
          end
        end

        def build_resource_identifier(serializer_data)
          {
            'type' => 'object',
            'required' => ['id', 'type'],
            'properties' => {
              'id' => {
                'type' => 'string',
                'format' => 'uuid'
              },
              'type' => {
                'type' => 'string',
                'enum' => [serializer_data[:type]]
              },
              'attributes' => build_attributes_schema(serializer_data),
              'relationships' => build_relationships_schema(serializer_data),
              'links' => {
                'type' => 'object',
                'properties' => {
                  'self' => { 'type' => 'string', 'format' => 'uri' }
                }
              }
            }
          }
        end

        def build_attributes_schema(serializer_data)
          attributes = serializer_data[:attributes] || []

          # Filter EE-only attributes if building CE spec
          attributes = attributes.reject { |attr| attr[:ee_only] } if @edition == :ce

          return { 'type' => 'object', 'properties' => {} } if attributes.empty?

          schema = {
            'type' => 'object',
            'properties' => {}
          }

          attributes.each do |attr|
            property_name = attr[:name].to_s.camelize(:lower)
            schema['properties'][property_name] = infer_attribute_type(attr)
          end

          schema
        end

        def build_relationships_schema(serializer_data)
          relationships = serializer_data[:relationships] || []

          # Filter EE-only relationships if building CE spec
          relationships = relationships.reject { |rel| rel[:ee_only] } if @edition == :ce

          return { 'type' => 'object', 'properties' => {} } if relationships.empty?

          schema = {
            'type' => 'object',
            'properties' => {}
          }

          relationships.each do |rel|
            property_name = rel[:name].to_s.camelize(:lower)
            schema['properties'][property_name] = {
              '$ref' => '#/components/schemas/JsonApiRelationship'
            }
          end

          schema
        end

        def infer_attribute_type(attr)
          # Best effort type inference based on attribute name
          name = attr[:name].to_s

          case name
          when /_(at|on)$/, /^(created|updated|last_|next_)/
            { 'type' => 'string', 'format' => 'date-time', 'nullable' => true }
          when /_count$/, /^(max_|uses$|cores$|memory$|disk$|duration$)/
            { 'type' => 'integer', 'nullable' => true }
          when /^(is_|has_|require_|suspended|protected|encrypted|strict|floating|use_)/
            { 'type' => 'boolean' }
          when 'metadata'
            { 'type' => 'object', 'additionalProperties' => true }
          when 'permissions'
            { 'type' => 'array', 'items' => { 'type' => 'string' } }
          when 'status'
            { 'type' => 'string' }
          when 'scheme'
            { 'type' => 'string', 'nullable' => true }
          else
            { 'type' => 'string', 'nullable' => true }
          end
        end
      end
    end
  end
end
