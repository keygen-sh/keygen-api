module CurrentRequestAttributes
  extend ActiveSupport::Concern

  included do
    before_action do
      # Allow custom request IDs to be specified via X-Request-Id, but only if
      # they match the UUID v4 format. This is used by Heroku.
      request.request_id = SecureRandom.uuid unless
        request.request_id.match?(UUID_REGEX)

      Current.request_id = request.request_id
      Current.host       = request.host
      Current.ip         = request.ip
    end
  end
end
