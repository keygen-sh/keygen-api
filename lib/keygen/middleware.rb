module Keygen
  module Middleware
    class CatchJsonParseErrors
      ACCEPTED_CONTENT_TYPES_REGEX = /(?:application\/json)|(?:application\/vnd\.api\+json)/

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue ActionDispatch::ParamsParser::ParseError => e
        raise e unless env['HTTP_ACCEPT'] =~ ACCEPTED_CONTENT_TYPES_REGEX

        [
          400,
          {
            "Content-Type" => "application/vnd.api+json",
          },
          [{
            errors: [{
              title: "Bad request",
              detail: "The request could not be completed because it contains invalid JSON"
            }]
          }.to_json]
        ]
      end
    end
  end
end