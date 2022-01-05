module CurrentRequestAttributes
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.request_id = request.request_id = SecureRandom.uuid
      Current.host       = request.host
      Current.ip         = request.ip
    end
  end
end
