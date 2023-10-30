# frozen_string_literal: true

ActiveSupport::Notifications.subscribe 'rack.attack' do |name, start, finish, request_id, data|
  req = data[:request]
  ip  = req.env['action_dispatch.remote_ip'] || req.ip
  fwd = req.env['HTTP_X_FORWARDED_FOR']

  case req.env['rack.attack.match_type']
  when :throttle
    Keygen.logger.info "[rack.attack] Rate limited: request_id=#{request_id} ip=#{ip} fwd=#{fwd} via=rack_attack"
  end
end

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |event|
  request = event.payload[:request]
  status  = event.payload[:status]
  next unless
    status >= 500

  err = event.payload[:exception_object] || $!
  next if
    err.nil?

  # NOTE(ezekg) Make sure we've logged the most recent error backtrace for 500s. Sometimes
  #             these get swallowed and it makes certain 500s hard to debug.
  Keygen.logger.error "[process_action.action_controller] request_id=#{request.uuid} status=#{status} class=#{err.class} message=#{err.message}"
  Keygen.logger.error err.backtrace&.join("\n")
rescue => e
  Keygen.logger.exception(e)
end
