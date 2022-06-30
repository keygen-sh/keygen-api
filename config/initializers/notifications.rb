# frozen_string_literal: true

ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, data|
  req = data[:request]
  ip  = req.env['action_dispatch.remote_ip'] || req.ip
  fwd = req.env['HTTP_X_FORWARDED_FOR']

  if req.env['rack.attack.match_type'] == :throttle
    Keygen.logger.info "[rack_attack] Rate limited: request_id=#{request_id} ip=#{ip} fwd=#{fwd}"
  end
end
