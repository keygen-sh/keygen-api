# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Schema
      class CommonSchemas
        # Returns hash of common/reusable schemas
        def self.all
          {
            'JsonApiDocument' => jsonapi_document,
            'JsonApiData' => jsonapi_data,
            'JsonApiRelationship' => jsonapi_relationship,
            'JsonApiLink' => jsonapi_link,
            'JsonApiMeta' => jsonapi_meta,
            'JsonApiError' => jsonapi_error,
            'JsonApiErrorResponse' => jsonapi_error_response,
            'Pagination' => pagination
          }
        end

        def self.jsonapi_document
          {
            'type' => 'object',
            'properties' => {
              'data' => {
                'oneOf' => [
                  { '$ref' => '#/components/schemas/JsonApiData' },
                  {
                    'type' => 'array',
                    'items' => { '$ref' => '#/components/schemas/JsonApiData' }
                  }
                ]
              },
              'included' => {
                'type' => 'array',
                'items' => { '$ref' => '#/components/schemas/JsonApiData' }
              },
              'meta' => { '$ref' => '#/components/schemas/JsonApiMeta' },
              'links' => {
                'type' => 'object',
                'additionalProperties' => { '$ref' => '#/components/schemas/JsonApiLink' }
              }
            }
          }
        end

        def self.jsonapi_data
          {
            'type' => 'object',
            'required' => ['id', 'type'],
            'properties' => {
              'id' => { 'type' => 'string' },
              'type' => { 'type' => 'string' },
              'attributes' => { 'type' => 'object' },
              'relationships' => {
                'type' => 'object',
                'additionalProperties' => { '$ref' => '#/components/schemas/JsonApiRelationship' }
              },
              'links' => {
                'type' => 'object',
                'additionalProperties' => { '$ref' => '#/components/schemas/JsonApiLink' }
              },
              'meta' => { '$ref' => '#/components/schemas/JsonApiMeta' }
            }
          }
        end

        def self.jsonapi_relationship
          {
            'type' => 'object',
            'properties' => {
              'data' => {
                'oneOf' => [
                  { 'type' => 'null' },
                  {
                    'type' => 'object',
                    'required' => ['id', 'type'],
                    'properties' => {
                      'id' => { 'type' => 'string' },
                      'type' => { 'type' => 'string' }
                    }
                  },
                  {
                    'type' => 'array',
                    'items' => {
                      'type' => 'object',
                      'required' => ['id', 'type'],
                      'properties' => {
                        'id' => { 'type' => 'string' },
                        'type' => { 'type' => 'string' }
                      }
                    }
                  }
                ]
              },
              'links' => {
                'type' => 'object',
                'properties' => {
                  'self' => { 'type' => 'string', 'format' => 'uri' },
                  'related' => { 'type' => 'string', 'format' => 'uri' }
                }
              },
              'meta' => { '$ref' => '#/components/schemas/JsonApiMeta' }
            }
          }
        end

        def self.jsonapi_link
          {
            'oneOf' => [
              { 'type' => 'string', 'format' => 'uri' },
              {
                'type' => 'object',
                'properties' => {
                  'href' => { 'type' => 'string', 'format' => 'uri' },
                  'meta' => { '$ref' => '#/components/schemas/JsonApiMeta' }
                }
              }
            ]
          }
        end

        def self.jsonapi_meta
          {
            'type' => 'object',
            'additionalProperties' => true
          }
        end

        def self.jsonapi_error
          {
            'type' => 'object',
            'properties' => {
              'id' => { 'type' => 'string' },
              'status' => { 'type' => 'string' },
              'code' => { 'type' => 'string' },
              'title' => { 'type' => 'string' },
              'detail' => { 'type' => 'string' },
              'source' => {
                'type' => 'object',
                'properties' => {
                  'pointer' => { 'type' => 'string' },
                  'parameter' => { 'type' => 'string' }
                }
              },
              'meta' => { '$ref' => '#/components/schemas/JsonApiMeta' }
            }
          }
        end

        def self.jsonapi_error_response
          {
            'type' => 'object',
            'required' => ['errors'],
            'properties' => {
              'errors' => {
                'type' => 'array',
                'items' => { '$ref' => '#/components/schemas/JsonApiError' }
              }
            }
          }
        end

        def self.pagination
          {
            'type' => 'object',
            'properties' => {
              'page' => {
                'type' => 'object',
                'properties' => {
                  'number' => { 'type' => 'integer' },
                  'size' => { 'type' => 'integer' },
                  'count' => { 'type' => 'integer' }
                }
              }
            }
          }
        end
      end
    end
  end
end
