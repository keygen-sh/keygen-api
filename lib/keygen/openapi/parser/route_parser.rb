# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Parser
      class RouteParser
        # Parse Rails routes and extract API v1 routes
        def parse(rails_routes)
          routes = []

          rails_routes.each do |route|
            next unless api_v1_route?(route)
            next if internal_route?(route)

            route_data = extract_route_data(route)
            routes << route_data if route_data
          end

          routes
        end

        private

        def api_v1_route?(route)
          path = route.path.spec.to_s
          path.include?('/v1/') || path.match?(%r{^/v1/})
        end

        def internal_route?(route)
          path = route.path.spec.to_s
          return true if path.include?('/-/')
          return true if route.name.to_s.start_with?('rails_')

          false
        end

        def extract_route_data(route)
          return nil unless route.verb

          verb_source = route.verb.source rescue route.verb.to_s
          return nil unless verb_source

          http_verb = verb_source.gsub(/[$^]/, '').split('|').first
          return nil unless http_verb

          http_verb = http_verb.downcase.to_sym

          {
            verb: http_verb,
            path: normalize_path(route.path.spec.to_s),
            name: route.name,
            controller: extract_controller(route),
            action: route.defaults[:action],
            constraints: route.constraints,
            defaults: route.defaults,
            format: route.defaults[:format]
          }
        end

        def normalize_path(path)
          # Convert Rails path to OpenAPI path
          # /v1/accounts/:account_id/licenses/:id(.:format)
          # becomes
          # /v1/accounts/{account_id}/licenses/{id}

          path
            .gsub(/\(\.:format\)$/, '')           # Remove optional format
            .gsub(/:([a-z_]+)/, '{\1}')           # Convert :param to {param}
            .gsub(%r{/api/v1}, '/v1')             # Normalize API prefix
        end

        def extract_controller(route)
          controller_class = route.defaults[:controller]
          return nil unless controller_class

          # Convert 'api/v1/licenses' to 'Api::V1::LicensesController'
          "#{controller_class.camelize}Controller"
        end
      end
    end
  end
end
