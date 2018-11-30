module Keygen
  module Middleware
    class RequestLogger
      IGNORED_ORIGINS = %w[https://app.keygen.sh].freeze
      IGNORED_RESOURCES = %w[
        webhook_endpoints
        webhook_events
        request_logs
        accounts
        searches
        metrics
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

        account_id = req.params[:account_id] || req.params[:id]
        route = Rails.application.routes.recognize_path req.url, method: req.method
        controller = route[:controller]

        if account_id.nil? || controller.nil? || IGNORED_RESOURCES.any? { |r| controller.include?(r) }
          return [status, headers, res]
        end

        # TODO(ezekg) Log the current bearer's ID and type
        RequestLogWorker.perform_async(
          account_id,
          {
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

    class CatchJsonParseErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue ActionDispatch::Http::Parameters::ParseError => e
        raise e unless env["HTTP_ACCEPT"] =~ /application\/(vnd\.api\+)?json/ ||
                       env["HTTP_ACCEPT"] == "*/*"

        [
          400,
          {
            "Content-Type" => "application/vnd.api+json",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: "The request could not be completed because it contains invalid JSON",
              code: "JSON_INVALID"
            }]
          }.to_json]
        ]
      end
    end

    class CatchBadUriErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue ActionController::RoutingError => e
        raise e unless e.message =~ /bad URI\(is not URI\?\)/

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
      end
    end

    class CatchRoutingErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue ActionController::RoutingError => e
        [
          404,
          {
            "Content-Type" => "application/vnd.api+json",
          },
          [{
            errors: [{
              title: "Not found",
              detail: "The requested resource was not found"
            }]
          }.to_json]
        ]
      end
    end
  end
end