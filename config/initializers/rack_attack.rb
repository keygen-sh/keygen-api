# frozen_string_literal: true

WHITELISTED_DOMAINS = %w[
  dist.keygen.sh
  app.keygen.sh
]

Rack::Attack.safelist("req/allow/localhost") do |rack_req|
  req = ActionDispatch::Request.new rack_req.env
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

  "127.0.0.1" == ip || "::1" == ip unless Rails.env.development?
rescue => e
  Keygen.logger.exception(e)

  false
end

Rack::Attack.safelist("req/allow/internal") do |rack_req|
  req    = ActionDispatch::Request.new rack_req.env
  origin = URI.parse(req.headers['origin']) rescue nil

  WHITELISTED_DOMAINS.include?(req.host) || (
    !origin.nil? && WHITELISTED_DOMAINS.include?(origin.host)
  )
rescue => e
  Keygen.logger.exception(e)

  false
end

Rack::Attack.blocklist("req/block/ip") do |rack_req|
  req = ActionDispatch::Request.new rack_req.env
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

  !Rack::Attack.cache.read("req/block/ip:#{ip}").nil?
rescue => e
  Keygen.logger.exception(e)

  false
end

req_limit_proc = lambda do |base_req_limit|
  lambda do |rack_req|
    req  = ActionDispatch::Request.new rack_req.env
    auth = req.headers.fetch('authorization') { '' }

    return base_req_limit if
      auth.blank?

    token =
      case
      when auth.starts_with?('Basic ')
        Base64.decode64(auth.remove('Basic ')).split(':').first
      when auth.starts_with?('Bearer ')
        auth.remove('Bearer ')
      else
        nil
      end

    return base_req_limit if
      token.blank?

    # Certain roles get to make additional RPS (e.g. admin/prod indicates server-side)
    case
    when token.starts_with?('admin-'),
         token.starts_with?('admi-'),
         token.starts_with?('prod-'),
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
  req = ActionDispatch::Request.new rack_req.env
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

  matches = req.path.match /^\/v\d+\/accounts\/([^\/]+)\//
  account = matches[1] unless matches.nil?

  if account.present?
    "#{account}/#{ip}"
  else
    ip
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
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

  matches = req.path.match(/^\/v\d+\/accounts\/([^\/]+)\//)
  next if
    matches.nil?

  account = matches[1]
  next unless
    account.present?

  auth = req.headers.fetch('authorization')
  next unless
    auth.present? && auth.starts_with?('Basic ')

  dec   = Base64.decode64(auth.remove('Basic '))
  email = dec.split(':').first
  next unless
    email.include?('@')

  hash = Digest::SHA2.hexdigest(email.to_s.downcase)

  "#{account}/#{ip}/#{hash}"
rescue => e
  Keygen.logger.exception(e)

  nil
end

# Rate limit password reset requests
Rack::Attack.throttle("req/ip/rstpwd", limit: 5, period: 1.minute) do |rack_req|
  next unless
    rack_req.post? && rack_req.path.ends_with?('/passwords')

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

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
Rack::Attack.throttle("req/ip/mutpwd", limit: 5, period: 1.minute) do |rack_req|
  next unless
    rack_req.post? && (
      rack_req.path.ends_with?('/update-password') ||
      rack_req.path.ends_with?('/reset-password')
    )

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

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
Rack::Attack.throttle("req/ip/mfa", limit: 5, period: 1.minute) do |rack_req|
  next unless
    rack_req.post? && rack_req.path.ends_with?('/second-factors')

  req = ActionDispatch::Request.new(rack_req.env)
  ip  = req.headers.fetch('cf-connecting-ip') { req.ip }

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

Rack::Attack.throttled_response = -> (env) {
  match_data = env["rack.attack.match_data"] || {}
  match_key  = env['rack.attack.matched'] || ''

  window = match_key.split('/').last
  count  = match_data[:count].to_i
  period = match_data[:period].to_i
  limit  = match_data[:limit].to_i
  now    = Time.current

  [
    429,
    {
      "Content-Type" => "application/vnd.api+json",
      "X-RateLimit-Window" => window.to_s,
      "X-RateLimit-Count" => count.to_s,
      "X-RateLimit-Limit" => limit.to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (period - now.to_i % period)).to_i.to_s
    },
    [{
      errors: [{
        title: "Throttle limit reached",
        detail: "Throttle limit has been reached for your IP address. Please see https://keygen.sh/docs/api/#rate-limiting for more info."
      }]
    }.to_json]
  ]
}

Rack::Attack.blocklisted_response = -> (env) {
  [
    403,
    {
      "Content-Type" => "application/vnd.api+json",
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
