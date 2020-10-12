# frozen_string_literal: true

require_relative './store'

module Keygen
  module Middleware
    class RequestStore
      def initialize(app)
        @app = app
      end

      def call(env)
        Keygen::Store::Request.initialize!

        status, headers, res = @app.call env

        Keygen::Store::Request.clear!

        [status, headers, res]
      end
    end

    class RequestCountLogger
      IGNORED_ORIGINS = %w[https://app.keygen.sh https://dist.keygen.sh].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        req = ActionDispatch::Request.new env
        status, headers, res = @app.call env

        if IGNORED_ORIGINS.include?(req.headers['origin'])
          return [status, headers, res]
        end

        begin
          account = Keygen::Store::Request.store[:current_account]
          return [status, headers, res] if account.nil?

          Rails.cache.increment Account.daily_request_count_cache_key(account.id), 1, expires_in: 1.day
        rescue => e
          Raygun.track_exception e
        end

        [status, headers, res]
      end
    end

    class RequestLogger
      IGNORED_ORIGINS = %w[https://app.keygen.sh https://dist.keygen.sh].freeze
      IGNORED_RESOURCES = %w[
        webhook_endpoints
        webhook_events
        request_logs
        accounts
        searches
        metrics
        analytics
        health
        stripe
        plans
      ].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        req = ActionDispatch::Request.new env
        status, headers, res = @app.call env

        if IGNORED_ORIGINS.include?(req.headers['origin'])
          return [status, headers, res]
        end

        requestor = Keygen::Store::Request.store[:current_bearer]
        account = Keygen::Store::Request.store[:current_account]
        route = Rails.application.routes.recognize_path req.url, method: req.method
        controller = route[:controller]

        if account.nil? || controller.nil? || IGNORED_RESOURCES.any? { |r| controller.include?(r) }
          return [status, headers, res]
        end

        RequestLogWorker.perform_async(
          account.id,
          {
            requestor_type: requestor&.class&.name,
            requestor_id: requestor&.id,
            request_id: req.request_id,
            url: req.fullpath,
            method: req.method,
            ip: req.headers['cf-connecting-ip'] || req.remote_ip,
            user_agent: req.user_agent
          },
          {
            status: status
          }
        )

        [status, headers, res]
      rescue => e
        Raygun.track_exception e

        raise e
      end
    end

    class RequestErrorWrapper
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue ActionDispatch::Http::Parameters::ParseError,
             Rack::QueryParser::InvalidParameterError,
             Rack::QueryParser::ParameterTypeError,
             ActionController::BadRequest,
             JSON::ParserError,
             ArgumentError => e
        message = e.message.scrub

        case message
        when /incomplete multibyte character/,
             /invalid escaped character/,
             /invalid byte sequence/
          [
            400,
            {
              "Content-Type" => "application/vnd.api+json",
            },
            [{
              errors: [{
                title: "Bad request",
                detail: "The request could not be completed because it contains an invalid byte sequence (check encoding)",
                code: "ENCODING_INVALID"
              }]
            }.to_json]
          ]
        when /string contains null byte/
          [
            400,
            {
              "Content-Type" => "application/vnd.api+json",
            },
            [{
              errors: [{
                title: "Bad request",
                detail: "The request could not be completed because it contains an unexpected null byte (check encoding)",
                code: "ENCODING_INVALID"
              }]
            }.to_json]
          ]
        when /query parameters/
          [
            400,
            {
              "Content-Type" => "application/vnd.api+json",
            },
            [{
              errors: [{
                title: "Bad request",
                detail: "The request could not be completed because it contains invalid query parameters (check encoding)",
                code: "PARAMETERS_INVALID"
              }]
            }.to_json]
          ]
        else
          if e.is_a?(ArgumentError)
            # Special case (report error and consider this a bug)
            Raygun.track_exception e, env.to_h.slice(
              "REQUEST_METHOD",
              "PATH_INFO",
              "QUERY_STRING",
              "CONTENT_LENGTH",
              "CONTENT_TYPE",
              "HTTP_ACCEPT"
            )

            [
              400,
              {
                "Content-Type" => "application/vnd.api+json",
              },
              [{
                errors: [{
                  title: "Bad request",
                  detail: "The request could not be completed because it was invalid",
                  code: "REQUEST_INVALID"
                }]
              }.to_json]
            ]
          else
            [
              400,
              {
                "Content-Type" => "application/vnd.api+json",
              },
              [{
                errors: [{
                  title: "Bad request",
                  detail: "The request could not be completed because it contains invalid JSON (check formatting/encoding)",
                  code: "JSON_INVALID"
                }]
              }.to_json]
            ]
          end
        end
      rescue ActionController::RoutingError => e
        message = e.message.scrub

        case message
        when /bad URI\(is not URI\?\)/
          [
            400,
            {
              "Content-Type" => "application/vnd.api+json",
            },
            [{
              errors: [{
                title: "Bad request",
                detail: "The request could not be completed because the URI was invalid (please ensure non-URL safe chars are properly encoded)",
                code: "URI_INVALID"
              }]
            }.to_json]
          ]
        else
          [
            404,
            {
              "Content-Type" => "application/vnd.api+json",
            },
            [{
              errors: [{
                title: "Not found",
                detail: "The requested resource was not found (please ensure your API endpoint is correct)"
              }]
            }.to_json]
          ]
        end
      rescue Rack::Timeout::RequestTimeoutException,
             Rack::Timeout::Error,
             Timeout::Error => e
        Raygun.track_exception e, env.to_h.slice(
          "REQUEST_METHOD",
          "PATH_INFO",
          "QUERY_STRING",
          "CONTENT_LENGTH",
          "CONTENT_TYPE",
          "HTTP_ACCEPT"
        )

        [
          503,
          {
            "Content-Type" => "application/vnd.api+json",
          },
          [{
            errors: [{
              title: "Request timeout",
              detail: "The request timed out because the server took too long to respond"
            }]
          }.to_json]
        ]
      rescue ActionController::UnknownHttpMethod => e
        [
          400,
          {
            "Content-Type" => "application/vnd.api+json",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: "The HTTP method for the request is not valid",
              code: "HTTP_METHOD_INVALID"
            }]
          }.to_json]
        ]
      end
    end

    class DefaultContentType
      def initialize app
        @app = app
      end

      def call(env)
        if env['CONTENT_TYPE'] == 'application/x-www-form-urlencoded'
          env['CONTENT_TYPE'] = 'application/json'
        end

        @app.call env
      end
    end
  end
end