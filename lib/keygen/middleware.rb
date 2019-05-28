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

    class RequestLogger
      IGNORED_ORIGINS = %w[https://app.keygen.sh].freeze
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

        # TODO(ezekg) Use current account from request store? Has the side effect of not
        #             counting invalid requests e.g. 400 and 404 errors.
        account_id = req.params[:account_id] || req.params[:id]
        route = Rails.application.routes.recognize_path req.url, method: req.method
        controller = route[:controller]

        if account_id.nil? || controller.nil? || IGNORED_RESOURCES.any? { |r| controller.include?(r) }
          return [status, headers, res]
        end

        requestor = Keygen::Store::Request.store[:current_bearer]

        RequestLogWorker.perform_async(
          account_id,
          {
            requestor_type: requestor&.class&.name,
            requestor_id: requestor&.id,
            request_id: req.request_id,
            url: req.path,
            method: req.method,
            ip: req.ip,
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
             # I have no idea why this is a bad request error - it should
             # be one of the above Rack errors, but for some reason, by the
             # time it propagates here, it's a different error.
             ActionController::BadRequest => e
        if e.message =~ /query parameters/
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
          [
            400,
            {
              "Content-Type" => "application/vnd.api+json",
            },
            [{
              errors: [{
                title: "Bad request",
                detail: "The request could not be completed because it contains invalid JSON (check encoding)",
                code: "JSON_INVALID"
              }]
            }.to_json]
          ]
        end
      rescue ActionController::RoutingError => e
        if e.message =~ /bad URI\(is not URI\?\)/
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
      rescue Rack::Timeout::Error
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