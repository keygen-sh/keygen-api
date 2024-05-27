# frozen_string_literal: true

RACK_ATTACK_IP_WHITELIST = ENV.fetch('RACK_ATTACK_IP_WHITELIST') { '' }
                              .split(',')
                              .map { IPAddr.new(_1.strip) }

RACK_ATTACK_IP_BLACKLIST = ENV.fetch('RACK_ATTACK_IP_BLACKLIST') { '' }
                              .split(',')
                              .map { IPAddr.new(_1.strip) }

Rack::Attack.safelist("req/allow/localhost") do |rack_req|
  next unless Rails.env.development?

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  "127.0.0.1" == ip || "::1" == ip
rescue => e
  Keygen.logger.exception(e)

  false
end

Rack::Attack.safelist("req/allow/ip") do |rack_req|
  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  RACK_ATTACK_IP_WHITELIST.any? { _1 === ip }
rescue => e
  Keygen.logger.exception(e)

  false
end

Rack::Attack.blocklist("req/block/ip") do |rack_req|
  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  RACK_ATTACK_IP_BLACKLIST.any? { _1 === ip }
rescue => e
  Keygen.logger.exception(e)

  false
end

Rack::Attack.blocklist("req/block/bots") do |rack_req|
  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  Rack::Attack::Fail2Ban.filter("req/block/bots/#{ip}", maxretry: 3, findtime: 10.minutes, bantime: 30.minutes) do
    CGI.unescape(req.query_string) =~ %r{/etc/(passwd|profile)} ||
      req.path.include?("/etc/profile") ||
      req.path.include?("/etc/passwd") ||
      req.path.include?("/wp-content") ||
      req.path.include?("/wp-admin") ||
      req.path.include?("/wp-login") ||
      req.path.include?("/cgi-bin") ||
      req.path.match?(/\S+\.(php|cgi)$/)
  end
end

req_limit_proc = lambda do |base_req_limit|
  lambda do |rack_req|
    req = ActionDispatch::Request.new(rack_req.env)

    # Parse authentication scheme
    auth_parts  = req.authorization.to_s.split(' ', 2)
    auth_scheme = auth_parts.first&.downcase

    token = case auth_scheme
            when 'license',
                 'bearer',
                 'token'
              auth_parts.second
            when 'basic'
              basic_auth = Base64.decode64(auth_parts.second.to_s)
              user, pass = basic_auth.to_s.split(':', 2)
              case user
              when 'license' then pass
              when 'token'   then pass
              else                user.presence
              end
            else
              query_auth = req.query_parameters['token'] || req.query_parameters['auth']
              user, pass = query_auth.to_s.split(':', 2)
              case user
              when 'license' then pass
              when 'token'   then pass
              else                user.presence
              end
            end

    return base_req_limit if
      token.blank?

    # Certain roles get to make additional RPS (e.g. admin/prod indicates server-side)
    case
    when token.starts_with?('admin-'),
         token.starts_with?('admi-'),
         token.starts_with?('prod-'),
         token.starts_with?('sales-'),
         token.starts_with?('dev-')
      base_req_limit * 5
    when token.starts_with?('activ-'),
         token.starts_with?('user-')
      base_req_limit * 2
    else
      base_req_limit
    end
  rescue => e
    Keygen.logger.exception(e)

    base_req_limit
  end
end

ip_limit_proc = lambda do |rack_req|
  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  matches = req.path.match /^\/v\d+\/accounts\/([^\/]+)\//
  account = matches[1] unless
    matches.nil?

  # Parse authentication scheme
  auth_parts  = req.authorization.to_s.split(' ', 2)
  auth_scheme = auth_parts.first&.downcase

  token = case auth_scheme
          when 'license',
               'bearer',
               'token'
            auth_parts.second
          when 'basic'
            basic_auth = Base64.decode64(auth_parts.second.to_s)
            user, pass = basic_auth.to_s.split(':', 2)
            case user
            when 'license' then pass
            when 'token'   then pass
            else                user.presence
            end
          else
            query_auth = req.query_parameters['token'] || req.query_parameters['auth']
            user, pass = query_auth.to_s.split(':', 2)
            case user
            when 'license' then pass
            when 'token'   then pass
            else                user.presence
            end
          end

  hash = Digest::SHA2.hexdigest(token.to_s)

  if account.present?
    "#{account}/#{ip}/#{hash}"
  else
    "#{ip}/#{hash}"
  end
rescue => e
  Keygen.logger.exception(e)

  nil
end

Rack::Attack.throttle("req/ip/burst/30s", { limit: req_limit_proc.call(60),    period: 30.seconds }, &ip_limit_proc)
Rack::Attack.throttle("req/ip/burst/2m",  { limit: req_limit_proc.call(600),   period: 2.minutes },  &ip_limit_proc)
Rack::Attack.throttle("req/ip/burst/5m",  { limit: req_limit_proc.call(1_500), period: 5.minutes },  &ip_limit_proc)
Rack::Attack.throttle("req/ip/burst/10m", { limit: req_limit_proc.call(3_000), period: 10.minutes }, &ip_limit_proc)

# Rate limit token creation (i.e. authentication)
Rack::Attack.throttle("req/ip/auth", limit: 5, period: 1.minute) do |rack_req|
  next unless
    rack_req.post? && rack_req.path.ends_with?('/tokens')

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  matches = req.path.match(/^\/v\d+\/accounts\/([^\/]+)\//)
  next if
    matches.nil?

  account = matches[1]
  next unless
    account.present?

  auth = req.headers.fetch('authorization') { '' }
  next unless
    auth.present? && auth.starts_with?('Basic ')

  dec   = Base64.decode64(auth.remove('Basic '))
  email = dec.split(':', 2).first
  next unless
    email.present? && email.include?('@')

  hash = Digest::SHA2.hexdigest(email.to_s.downcase)

  "#{account}/#{ip}/#{hash}"
rescue => e
  Keygen.logger.exception(e)

  nil
end

# Rate limit password reset requests
Rack::Attack.throttle("req/ip/rstpwd", limit: 5, period: 1.hour) do |rack_req|
  next unless
    rack_req.post? && rack_req.path.ends_with?('/passwords')

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  matches = req.path.match(/^\/v\d+\/accounts\/([^\/]+)\//)
  next if
    matches.nil?

  account = matches[1]
  next unless
    account.present?

  email = req.params.dig(:meta, :email)
  next unless
    email.present?

  hash = Digest::SHA2.hexdigest(email.to_s.downcase)

  "#{account}/#{ip}/#{hash}"
rescue => e
  Keygen.logger.exception(e)

  nil
end

# Rate limit password mutations (i.e. update password, reset password)
Rack::Attack.throttle("req/ip/mutpwd", limit: 5, period: 10.minutes) do |rack_req|
  next unless
    rack_req.post? && (
      rack_req.path.ends_with?('/update-password') ||
      rack_req.path.ends_with?('/reset-password')
    )

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  matches = req.path.match(/^\/v\d+\/accounts\/([^\/]+)\/users\/([^\/]+)\//)
  next if
    matches.nil?

  account = matches[1]
  next unless
    account.present?

  user = matches[2]
  next unless
    user.present?

  hash = Digest::SHA2.hexdigest(user.to_s.downcase)

  "#{account}/#{ip}/#{hash}"
rescue => e
  Keygen.logger.exception(e)

  nil
end

# Rate limit MFA mutations (i.e. second factors, etc.)
Rack::Attack.throttle("req/ip/mutmfa", limit: 5, period: 10.minutes) do |rack_req|
  next unless
    (rack_req.post? && rack_req.path.ends_with?('/second-factors')) ||
    (rack_req.delete? && rack_req.path.include?('/second-factors/')) ||
    (rack_req.patch? && rack_req.path.include?('/second-factors/')) ||
    (rack_req.put? && rack_req.path.include?('/second-factors/'))

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.remote_ip

  matches = req.path.match(/^\/v\d+\/accounts\/([^\/]+)\/users\/([^\/]+)\//)
  next if
    matches.nil?

  account = matches[1]
  next unless
    account.present?

  user = matches[2]
  next unless
    user.present?

  hash = Digest::SHA2.hexdigest(user.to_s.downcase)

  "#{account}/#{ip}/#{hash}"
rescue => e
  Keygen.logger.exception(e)

  nil
end

Rack::Attack.throttled_responder = -> req {
  match_data = req.env["rack.attack.match_data"] || {}
  match_key  = req.env['rack.attack.matched'] || ''

  window      = match_key.split('/').last
  count       = match_data[:count].to_i
  period      = match_data[:period].to_i
  limit       = match_data[:limit].to_i
  now         = match_data[:epoch_time].to_i
  retry_after = period - (now % period)

  [
    429,
    {
      "Content-Type" => "application/vnd.api+json; charset=utf-8",
      "X-RateLimit-Window" => window.to_s,
      "X-RateLimit-Count" => count.to_s,
      "X-RateLimit-Limit" => limit.to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (period - now.to_i % period)).to_i.to_s,
      "Retry-After" => retry_after.to_s,
    },
    [{
      errors: [{
        title: "Too many requests",
        detail: "Throttle limit has been reached for your IP address. Please slow down. See https://keygen.sh/docs/api/#rate-limiting for more info.",
        code: "TOO_MANY_REQUESTS",
      }]
    }.to_json]
  ]
}

Rack::Attack.blocklisted_responder = -> req {
  [
    403,
    {
      "Content-Type" => "application/vnd.api+json; charset=utf-8",
      "X-RateLimit-Window" => "blacklist",
      "X-RateLimit-Count" => "0",
      "X-RateLimit-Limit" => "0",
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => "0"
    },
    [{
      errors: [{
        title: "Forbidden",
        detail: "Your IP address has been temporarily blacklisted due to abusive behavior. Please see https://keygen.sh/docs/api/#rate-limiting for more info."
      }]
    }.to_json]
  ]
}
