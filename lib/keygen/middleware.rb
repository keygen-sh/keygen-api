# frozen_string_literal: true

require_relative "./logger"
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
          Keygen.logger.exception(e)
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

      def initialize(app)
        @app = app
      end

      def call(env)
        req = ActionDispatch::Request.new env
        status, headers, res = @app.call env

        is_ignored_origin = IGNORED_ORIGINS.include?(req.headers['origin'])
        return [status, headers, res] if is_ignored_origin

        account = Keygen::Store::Request.store[:current_account]
        account_id = account&.id || req.params[:account_id] || req.params[:id]

        route = Rails.application.routes.recognize_path req.url, method: req.method
        controller = route[:controller]
        action = route[:action]

        is_ignored_resource = account_id.nil? || controller.nil? || IGNORED_RESOURCES.any? { |r| controller.include?(r) }
        return [status, headers, res] if is_ignored_resource

        resource = Keygen::Store::Request.store[:current_resource]
        requestor = Keygen::Store::Request.store[:current_bearer]

        begin
          filtered_req_params = req.filtered_parameters.slice(:meta, :data)
          filtered_req_body   =
            if filtered_req_params.present?
              params = filtered_req_params.deep_transform_keys! { |k| k.to_s.camelize :lower }

              params.to_json
            else
              nil
            end
        rescue => e
          Keygen.logger.exception(e)
        end

        begin
          filtered_req_path = req.filtered_path ||
                              req.original_fullpath
        rescue => e
          Keygen.logger.exception(e)
        end

        begin
          http_date =
            if headers.key?('Date')
              Time.httpdate(headers['Date'])
            else
              Time.current
            end
        rescue => e
          Keygen.logger.exception(e)
        end

        # This could be a Rack::BodyProxy or an array of JSON responses (see below middlewares)
        begin
          body =
            if res.respond_to?(:body)
              res.body
            else
              res.first
            end
        rescue => e
          Keygen.logger.exception(e)
        end

        begin
          sig = headers['X-Signature'] || headers['Keygen-Signature']
        rescue => e
          Keygen.logger.exception(e)
        end

        begin
          user_agent =
            if req.user_agent.present? && req.user_agent.valid_encoding?
              req.user_agent.encode('ascii', invalid: :replace, undef: :replace)
            else
              nil
            end
        rescue => e
          Keygen.logger.exception(e)
        end

        RequestLogWorker.perform_async(
          account_id,
          {
            requestor_type: requestor&.class&.name,
            requestor_id: requestor&.id,
            resource_type: resource&.class&.name,
            resource_id: resource&.id,
            request_time: http_date || Time.current,
            request_id: req.request_id,
            user_agent: user_agent,
            ip: req.remote_ip,
            method: req.method,
            url: filtered_req_path,
            body: filtered_req_body,
          },
          {
            signature: sig,
            status: status,
            body: body,
          }
        )

        [status, headers, res]
      rescue => e
        Keygen.logger.exception(e)

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
            Keygen.logger.exception(e)

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
        Keygen.logger.exception(e)

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
      rescue ActionDispatch::Http::MimeNegotiation::InvalidType
        [
          400,
          {
            "Content-Type" => "application/vnd.api+json",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: "The content type of the request is not acceptable (check content-type header)",
              code: "CONTENT_TYPE_INVALID"
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
