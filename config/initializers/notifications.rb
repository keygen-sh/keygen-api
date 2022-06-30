# frozen_string_literal: true

ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, data|
  req = data[:request]

  if req.env['rack.attack.match_type'] == :throttle
    Keygen.logger.info "[rack_attack] Rate limited: request_id=#{request_id} ip=#{req.remote_ip}"
  end
end
