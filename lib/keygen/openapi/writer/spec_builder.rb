# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Writer
      class SpecBuilder
        CURRENT_API_VERSION = '1.7'

        attr_reader :routes, :controllers, :serializers, :edition, :monolithic

        def initialize(routes, controllers, serializers, edition: :ce, monolithic: false)
          @routes = routes
          @controllers = controllers
          @serializers = serializers
          @edition = edition
          @monolithic = monolithic
          @ref_resolver = RefResolver.new(monolithic: monolithic)
          @param_builder = Schema::ParameterSchemaBuilder.new
          @request_builder = Schema::RequestBodyBuilder.new
          @response_builder = Schema::ResponseSchemaBuilder.new(edition: edition)
        end

        def build
          if monolithic
            {
              root: build_monolithic_root_spec,
              common_schemas: build_common_schemas_data,
              paths: build_paths_data,
              schemas: build_schemas_data,
              parameters: build_common_parameters_data,
              responses: build_common_responses_data
            }
          else
            {
              root: build_root_spec,
              common_schemas: build_common_schemas,
              paths: build_paths_data,
              schemas: {},
              parameters: build_common_parameters,
              responses: build_common_responses
            }
          end
        end

        private

        def build_root_spec
          {
            'openapi' => '3.1.0',
            'info' => build_info,
            'servers' => build_servers,
            'paths' => build_path_refs,
            'components' => {
              'schemas' => build_schema_refs,
              'parameters' => build_parameter_refs,
              'responses' => build_response_refs,
              'securitySchemes' => build_security_schemes
            },
            'security' => [
              { 'BearerAuth' => [] }
            ],
            'tags' => build_tags
          }
        end

        def build_monolithic_root_spec
          {
            'openapi' => '3.1.0',
            'info' => build_info,
            'servers' => build_servers,
            'paths' => {}, # Will be inlined by YamlWriter
            'components' => {
              'schemas' => {}, # Will be inlined by YamlWriter
              'parameters' => {}, # Will be inlined by YamlWriter
              'responses' => {}, # Will be inlined by YamlWriter
              'securitySchemes' => build_security_schemes
            },
            'security' => [
              { 'BearerAuth' => [] }
            ],
            'tags' => build_tags
          }
        end

        def build_info
          {
            'title' => edition == :ce ? 'Keygen API' : 'Keygen API (Enterprise Edition)',
            'version' => CURRENT_API_VERSION,
            'description' => build_description,
            'contact' => {
              'name' => 'Keygen Support',
              'url' => 'https://keygen.sh',
              'email' => 'support@keygen.sh'
            }
          }
        end

        def build_description
          desc = "The Keygen API is a REST API for managing software licenses, users, machines, and more. "
          desc += "The API follows the JSON:API specification and uses standard HTTP methods and status codes."

          if edition == :ee
            desc += "\n\nThis is the Enterprise Edition specification, which includes all Community Edition features plus additional enterprise-only features."
          end

          desc
        end

        def build_servers
          [
            {
              'url' => 'https://api.keygen.sh',
              'description' => 'Production server'
            }
          ]
        end

        def build_path_refs
          refs = {}

          # Group routes by path
          routes.group_by { |r| r[:path] }.each_key do |path|
            filename = path_to_filename(path)
            refs[path] = { '$ref' => "./paths/#{filename}" }
          end

          refs
        end

        def build_paths_data
          paths_data = {}

          # Group routes by path
          routes.group_by { |r| r[:path] }.each do |path, path_routes|
            path_spec = {}

            # Group routes by HTTP method
            path_routes.group_by { |r| r[:verb] }.each do |verb, verb_routes|
              # For now, take the first route for each verb (we can enhance this later)
              route = verb_routes.first
              operation = build_operation(route)

              path_spec[verb.to_s] = operation if operation
            end

            paths_data[path] = path_spec unless path_spec.empty?
          end

          paths_data
        end

        def build_schema_refs
          refs = {}

          # Add common schemas
          Schema::CommonSchemas.all.each_key do |name|
            refs[name] = { '$ref' => "./schemas/common/#{name}.yaml" }
          end

          refs
        end

        def build_parameter_refs
          {
            'AccountIdParameter' => { '$ref' => './parameters/AccountIdParameter.yaml' },
            'IdParameter' => { '$ref' => './parameters/IdParameter.yaml' },
            'MachineComponentIdParameter' => { '$ref' => './parameters/MachineComponentIdParameter.yaml' },
            'MachineProcessIdParameter' => { '$ref' => './parameters/MachineProcessIdParameter.yaml' },
            'UserIdParameter' => { '$ref' => './parameters/UserIdParameter.yaml' },
            'KeyIdParameter' => { '$ref' => './parameters/KeyIdParameter.yaml' },
            'LicenseIdParameter' => { '$ref' => './parameters/LicenseIdParameter.yaml' },
            'MachineIdParameter' => { '$ref' => './parameters/MachineIdParameter.yaml' },
            'PolicyIdParameter' => { '$ref' => './parameters/PolicyIdParameter.yaml' },
            'ProductIdParameter' => { '$ref' => './parameters/ProductIdParameter.yaml' },
            'ReleaseIdParameter' => { '$ref' => './parameters/ReleaseIdParameter.yaml' },
            'GroupIdParameter' => { '$ref' => './parameters/GroupIdParameter.yaml' },
            'EnvironmentIdParameter' => { '$ref' => './parameters/EnvironmentIdParameter.yaml' },
            'FilenameParameter' => { '$ref' => './parameters/FilenameParameter.yaml' },
            'PackageParameter' => { '$ref' => './parameters/PackageParameter.yaml' },
            'ArtifactParameter' => { '$ref' => './parameters/ArtifactParameter.yaml' },
            'DigestParameter' => { '$ref' => './parameters/DigestParameter.yaml' },
            'GemParameter' => { '$ref' => './parameters/GemParameter.yaml' },
            'ReferenceParameter' => { '$ref' => './parameters/ReferenceParameter.yaml' },
            'PageNumberParameter' => { '$ref' => './parameters/PageNumberParameter.yaml' },
            'PageSizeParameter' => { '$ref' => './parameters/PageSizeParameter.yaml' }
          }
        end

        def build_response_refs
          {
            'UnauthorizedError' => { '$ref' => './responses/UnauthorizedError.yaml' },
            'ForbiddenError' => { '$ref' => './responses/ForbiddenError.yaml' },
            'NotFoundError' => { '$ref' => './responses/NotFoundError.yaml' },
            'UnprocessableEntityError' => { '$ref' => './responses/UnprocessableEntityError.yaml' },
            'TooManyRequestsError' => { '$ref' => './responses/TooManyRequestsError.yaml' },
            'InternalServerError' => { '$ref' => './responses/InternalServerError.yaml' }
          }
        end

        def build_security_schemes
          {
            'BearerAuth' => {
              'type' => 'http',
              'scheme' => 'bearer',
              'bearerFormat' => 'token',
              'description' => 'API token authentication using Bearer scheme'
            }
          }
        end

        def build_tags
          tags = []

          # Extract unique resource types from routes
          resource_types = routes.map { |r| extract_resource_type(r) }.compact.uniq.sort

          resource_types.each do |resource|
            tags << {
              'name' => resource,
              'description' => "Operations for #{resource}"
            }
          end

          tags
        end

        def build_common_schemas
          Schema::CommonSchemas.all
        end

        def build_common_schemas_data
          build_common_schemas
        end

        def build_schemas_data
          {} # For now, empty - can be expanded if needed
        end

        def build_common_parameters_data
          build_common_parameters
        end

        def build_common_responses_data
          build_common_responses
        end

        def build_common_parameters
          {
            'AccountIdParameter' => {
              'name' => 'account_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string', 'format' => 'uuid' },
              'description' => 'The unique identifier for the account'
            },
            'IdParameter' => {
              'name' => 'id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the resource'
            },
            'MachineComponentIdParameter' => {
              'name' => 'machine_component_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the machine component'
            },
            'MachineProcessIdParameter' => {
              'name' => 'machine_process_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the machine process'
            },
            'UserIdParameter' => {
              'name' => 'user_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the user'
            },
            'KeyIdParameter' => {
              'name' => 'key_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the key'
            },
            'LicenseIdParameter' => {
              'name' => 'license_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the license'
            },
            'MachineIdParameter' => {
              'name' => 'machine_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the machine'
            },
            'PolicyIdParameter' => {
              'name' => 'policy_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the policy'
            },
            'ProductIdParameter' => {
              'name' => 'product_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the product'
            },
            'ReleaseIdParameter' => {
              'name' => 'release_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the release'
            },
            'GroupIdParameter' => {
              'name' => 'group_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the group'
            },
            'EnvironmentIdParameter' => {
              'name' => 'environment_id',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The unique identifier for the environment'
            },
            'FilenameParameter' => {
              'name' => 'filename',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The filename'
            },
            'PackageParameter' => {
              'name' => 'package',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The package name'
            },
            'ArtifactParameter' => {
              'name' => 'artifact',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The artifact identifier'
            },
            'DigestParameter' => {
              'name' => 'digest',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The digest hash'
            },
            'GemParameter' => {
              'name' => 'gem',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The gem name'
            },
            'ReferenceParameter' => {
              'name' => 'reference',
              'in' => 'path',
              'required' => true,
              'schema' => { 'type' => 'string' },
              'description' => 'The reference identifier'
            },
            'PageNumberParameter' => {
              'name' => 'page[number]',
              'in' => 'query',
              'required' => false,
              'schema' => { 'type' => 'integer', 'minimum' => 1 },
              'description' => 'The page number to retrieve'
            },
            'PageSizeParameter' => {
              'name' => 'page[size]',
              'in' => 'query',
              'required' => false,
              'schema' => { 'type' => 'integer', 'minimum' => 1, 'maximum' => 100 },
              'description' => 'The number of items per page'
            }
          }
        end

        def build_common_responses
          {
            'UnauthorizedError' => {
              'description' => 'Unauthorized - Invalid or missing authentication token',
              'content' => {
                'application/vnd.api+json' => {
                  'schema' => { '$ref' => '#/components/schemas/JsonApiErrorResponse' }
                }
              }
            },
            'ForbiddenError' => {
              'description' => 'Forbidden - Insufficient permissions',
              'content' => {
                'application/vnd.api+json' => {
                  'schema' => { '$ref' => '#/components/schemas/JsonApiErrorResponse' }
                }
              }
            },
            'NotFoundError' => {
              'description' => 'Not Found - Resource does not exist',
              'content' => {
                'application/vnd.api+json' => {
                  'schema' => { '$ref' => '#/components/schemas/JsonApiErrorResponse' }
                }
              }
            },
            'UnprocessableEntityError' => {
              'description' => 'Unprocessable Entity - Validation failed',
              'content' => {
                'application/vnd.api+json' => {
                  'schema' => { '$ref' => '#/components/schemas/JsonApiErrorResponse' }
                }
              }
            },
            'TooManyRequestsError' => {
              'description' => 'Too Many Requests - Rate limit exceeded',
              'content' => {
                'application/vnd.api+json' => {
                  'schema' => { '$ref' => '#/components/schemas/JsonApiErrorResponse' }
                }
              }
            },
            'InternalServerError' => {
              'description' => 'Internal Server Error',
              'content' => {
                'application/vnd.api+json' => {
                  'schema' => { '$ref' => '#/components/schemas/JsonApiErrorResponse' }
                }
              }
            }
          }
        end

        def extract_resource_type(route)
          # Extract resource type from controller name or path
          controller = route[:controller]
          return nil unless controller

          controller.gsub(/Controller$/, '').split('::').last.underscore
        end

        def build_operation(route)
          operation = {
            'summary' => build_operation_summary(route),
            'responses' => build_operation_responses(route)
          }

          # Add parameters if any
          params = build_operation_parameters(route)
          operation['parameters'] = params unless params.empty?

          # Add request body for POST/PUT/PATCH
          if %i[post put patch].include?(route[:verb])
            operation['requestBody'] = build_request_body(route)
          end

          operation
        end

        def build_operation_summary(route)
          resource = extract_resource_type(route) || 'resource'
          action = route[:action]

          case route[:verb]
          when :get
            action == 'index' ? "List #{resource.pluralize}" : "Retrieve #{resource.singularize}"
          when :post
            "Create #{resource.singularize}"
          when :put, :patch
            "Update #{resource.singularize}"
          when :delete
            "Delete #{resource.singularize}"
          else
            "#{route[:verb].to_s.capitalize} #{resource}"
          end
        end

        def build_operation_parameters(route)
          params = []

          # Extract path parameters
          route[:path].scan(/\{([^}]+)\}/).flatten.each do |param_name|
            param_ref = case param_name
                        when 'account_id' then 'AccountIdParameter'
                        when 'id' then 'IdParameter'
                        when 'machine_component_id' then 'MachineComponentIdParameter'
                        when 'machine_process_id' then 'MachineProcessIdParameter'
                        when 'user_id' then 'UserIdParameter'
                        when 'key_id' then 'KeyIdParameter'
                        when 'license_id' then 'LicenseIdParameter'
                        when 'machine_id' then 'MachineIdParameter'
                        when 'policy_id' then 'PolicyIdParameter'
                        when 'product_id' then 'ProductIdParameter'
                        when 'release_id' then 'ReleaseIdParameter'
                        when 'group_id' then 'GroupIdParameter'
                        when 'environment_id' then 'EnvironmentIdParameter'
                        when 'filename' then 'FilenameParameter'
                        when 'package' then 'PackageParameter'
                        when 'artifact' then 'ArtifactParameter'
                        when 'digest' then 'DigestParameter'
                        when 'gem' then 'GemParameter'
                        when 'reference' then 'ReferenceParameter'
                        else "#{param_name.camelize}Parameter"
                        end

            if monolithic
              # Inline the parameter definition
              param_def = build_common_parameters[param_ref]
              params << param_def if param_def
            else
              params << { '$ref' => "#/components/parameters/#{param_ref}" }
            end
          end

          # Add common query parameters for GET requests
          if route[:verb] == :get
            if monolithic
              params << build_common_parameters['PageNumberParameter']
              params << build_common_parameters['PageSizeParameter']
            else
              params << { '$ref' => '#/components/parameters/PageNumberParameter' }
              params << { '$ref' => '#/components/parameters/PageSizeParameter' }
            end
          end

          params.compact
        end

        def build_operation_responses(route)
          responses = {}

          # Default successful response
          success_code = case route[:verb]
                         when :get then route[:action] == 'index' ? '200' : '200'
                         when :post then '201'
                         when :put, :patch then '200'
                         when :delete then '204'
                         else '200'
                         end

          responses[success_code] = { 'description' => 'Success' }

          # Add error responses
          %w[400 401 403 404 422 429 500].each do |code|
            error_name = error_code_to_name(code)
            if monolithic
              # Inline the response definition
              response_def = build_common_responses[error_name]
              responses[code] = response_def if response_def
            else
              responses[code] = { '$ref' => "#/components/responses/#{error_name}" }
            end
          end

          responses
        end

        def build_request_body(route)
          schema_ref = if monolithic
                        build_common_schemas['JsonApiDocument']
                      else
                        { '$ref' => '#/components/schemas/JsonApiDocument' }
                      end

          {
            'required' => true,
            'content' => {
              'application/vnd.api+json' => {
                'schema' => schema_ref
              }
            }
          }
        end

        def error_code_to_name(code)
          {
            '400' => 'BadRequestError',
            '401' => 'UnauthorizedError',
            '403' => 'ForbiddenError',
            '404' => 'NotFoundError',
            '422' => 'UnprocessableEntityError',
            '429' => 'TooManyRequestsError',
            '500' => 'InternalServerError'
          }[code] || 'InternalServerError'
        end

        def path_to_filename(path)
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
