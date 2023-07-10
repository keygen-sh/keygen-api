# frozen_string_literal: true

require_relative "./logger"

module Keygen
  module Middleware
    # FIXME(ezekg) Rails emits a lot of errors that can't be rescued within
    #              our ApplicationController. So here we are.
    #
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
             Encoding::CompatibilityError,
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
              "Content-Type" => "application/vnd.api+json; charset=utf-8",
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
              "Content-Type" => "application/vnd.api+json; charset=utf-8",
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
              "Content-Type" => "application/vnd.api+json; charset=utf-8",
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
            Keygen.logger.exception(e)

            [
              500,
              {
                "Content-Type" => "application/vnd.api+json; charset=utf-8",
              },
              [{
                errors: [{
                  title: "Internal server error",
                  detail: "Looks like something went wrong! Our engineers have been notified. If you continue to have problems, please contact support@keygen.sh.",
                }]
              }.to_json]
            ]
          else
            [
              400,
              {
                "Content-Type" => "application/vnd.api+json; charset=utf-8",
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
              "Content-Type" => "application/vnd.api+json; charset=utf-8",
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
              "Content-Type" => "application/vnd.api+json; charset=utf-8",
            },
            [{
              errors: [{
                title: "Not found",
                detail: "The requested endpoint was not found (check your HTTP method, Accept header, and URL path)",
                code: "NOT_FOUND",
              }]
            }.to_json]
          ]
        end
      rescue Rack::Timeout::RequestTimeoutException,
             Rack::Timeout::Error,
             Timeout::Error => e
        Keygen.logger.exception(e)

        [
          503,
          {
            "Content-Type" => "application/vnd.api+json; charset=utf-8",
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
            "Content-Type" => "application/vnd.api+json; charset=utf-8",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: "The HTTP method for the request is not valid",
              code: "HTTP_METHOD_INVALID"
            }]
          }.to_json]
        ]
      rescue ActionDispatch::Http::MimeNegotiation::InvalidType
        [
          400,
          {
            "Content-Type" => "application/vnd.api+json; charset=utf-8",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: "The content type of the request is not acceptable (check content-type header)",
              code: "CONTENT_TYPE_INVALID"
            }]
          }.to_json]
        ]
      rescue RequestMigrations::UnsupportedVersionError
        [
          400,
          {
            "Content-Type" => "application/vnd.api+json; charset=utf-8",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: 'unsupported API version requested',
              code: 'INVALID_API_VERSION',
              links: {
                about: 'https://keygen.sh/docs/api/versioning/',
              },
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
        content_type = env['CONTENT_TYPE'] || ''

        # Whenever an API request is sent without a content-type header, some clients,
        # such as `fetch()` or curl, use these headers by default. We're going to try
        # to parse the request as JSON and error later, instead of rejecting the request
        # off the bat. In theory, this would slightly improve onboarding DX.
        if content_type.empty? || content_type.include?('text/plain') || content_type.include?('application/x-www-form-urlencoded') || content_type.include?('multipart/form-data')
          begin
            request    = ActionDispatch::Request.new(env)
            route      = Rails.application.routes.recognize_path(request.url, request:) rescue {}
            controller = route[:controller]
            action     = route[:action]

            # Default to JSON content-type header for non-artifact endpoints
            env['CONTENT_TYPE'] = 'application/json' unless
              controller&.ends_with?('/release_artifacts') &&
              action == 'create'
          rescue => e
            Keygen.logger.exception(e)
          end
        end

        @app.call(env)
      end
    end

    class IgnoreForwardedHost
      def initialize(app)
        @app = app
      end

      def call(env)
        # Whenever an API request is received that originated via a proxy, such as
        # from Vercel/Next.js, this header may be set and it may be a different
        # value than our allowed hosts. Unfortunately, Rails uses this header
        # along with Host to authorize against our allowed hosts, so this
        # raises a 403 error for the bad host header.
        #
        # Since we don't use this header, and its only purpose is for telling
        # us the host used in the original request, before being proxied to
        # us, we can strip it out without consequence.
        #
        # See: https://github.com/rails/rails/issues/29893
        env.delete('HTTP_X_FORWARDED_HOST')

        @app.call(env)
      end
    end
  end
end
