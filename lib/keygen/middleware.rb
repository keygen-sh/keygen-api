module Keygen
  module Middleware
    class RequestLogger
      def initialize(app)
        @app = app
      end

      def call(env)
        req = ActionDispatch::Request.new env
        status, headers, res = @app.call env
        account_id = req.params[:account_id] || req.params[:id]

        RequestLogWorker.perform_async(
          account_id,
          {
            request_id: req.request_id,
            endpoint: req.path,
            method: req.method,
            ip: req.ip,
            user_agent: req.user_agent
          },
          {
            status: status
          }
        )

        [status, headers, res]
      end
    end

    class CatchJsonParseErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
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
  end
end