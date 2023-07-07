# frozen_string_literal: true

module CurrentRequestAttributes
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.request_id = request.request_id = SecureRandom.uuid
      Current.host       = request.host
      Current.ip         = request.remote_ip
    end
  end
end
