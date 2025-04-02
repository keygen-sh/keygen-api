# frozen_string_literal: true

module CurrentRequestAttributes
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.api_version = RequestMigrations.config.request_version_resolver.call(request)
      Current.request_id  = request.request_id = UUID7.generate
      Current.host        = request.host
      Current.ip          = request.remote_ip
    end
  end
end
