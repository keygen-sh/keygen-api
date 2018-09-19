module Keygen
  module Middleware
    class CatchJsonParseErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue ActionDispatch::ParamsParser::ParseError => e
        raise e unless env["HTTP_ACCEPT"] =~ /application\/(vnd\.api\+)?json/

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