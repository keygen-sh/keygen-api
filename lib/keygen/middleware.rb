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
      IGNORED_ORIGINS ||= %w[https://app.keygen.sh https://dist.keygen.sh].freeze

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
          account_id = account&.id || req.params[:account_id] || req.params[:id]
          if account_id.present?
            Rails.cache.increment Account.daily_request_count_cache_key(account_id), 1, expires_in: 1.day
          end
        rescue => e
          Rails.logger.error e
        end

        [status, headers, res]
      end
    end

    class RequestLogger
      IGNORED_ORIGINS ||= %w[https://app.keygen.sh https://dist.keygen.sh].freeze
      IGNORED_RESOURCES ||= %w[
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

      REDACTED_RESOURCES ||= %w[
        tokens/generate
        tokens/regenerate
        tokens/regenerate_current

        users/create
        users/update

        password/update_password
        password/reset_password
      ]

      def initialize(app)
        @app = app
      end

      def call(env)
        req = ActionDispatch::Request.new env
        status, headers, res = @app.call env
        return [status, headers, res] if IGNORED_ORIGINS.include?(req.headers['origin'])

        account = Keygen::Store::Request.store[:current_account]
        account_id = account&.id || req.params[:account_id] || req.params[:id]

        route = Rails.application.routes.recognize_path req.url, method: req.method
        controller = route[:controller]
        action = route[:action]

        is_ignored = account_id.nil? || controller.nil? || IGNORED_RESOURCES.any? { |r| controller.include?(r) }
        is_redacted = REDACTED_RESOURCES.any? { |r| "#{controller}/#{action}".include?(r) }
        return [status, headers, res] if is_ignored

        resource = Keygen::Store::Request.store[:current_resource]
        requestor = Keygen::Store::Request.store[:current_bearer]

        RequestLogWorker.perform_async(
          account_id,
          {
            requestor_type: requestor&.class&.name,
            requestor_id: requestor&.id,
            resource_type: resource&.class&.name,
            resource_id: resource&.id,
            request_id: req.request_id,
            body: is_redacted || !req.raw_post.present? ? nil : req.raw_post,
            url: req.fullpath,
            method: req.method,
            ip: req.headers['cf-connecting-ip'] || req.remote_ip,
            user_agent: req.user_agent,
          },
          {
            body: is_redacted ? nil : (res.respond_to?(:body) ? res.body : res.first),
            signature: headers['X-Signature'],
            status: status,
          }
        )

        [status, headers, res]
      rescue => e
        Rails.logger.error e

        raise e
      end
    end

    class RequestErrorWrapper
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue ArgumentError => e
        case e.message
        when /invalid byte sequence in UTF-8/,
             /incomplete multibyte character/
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
        else
          raise e
        end
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
      rescue Rack::Timeout::RequestTimeoutException,
             Rack::Timeout::Error,
             Timeout::Error => e
        Rails.logger.error e

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