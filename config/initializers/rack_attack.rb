# frozen_string_literal: true

WHITELISTED_DOMAINS = %w[dist.keygen.sh]

Rack::Attack.safelist("req/allow/localhost") do |req|
  ip = req.fetch_header('cf-connecting-ip') { req.ip }

  "127.0.0.1" == ip || "::1" == ip unless Rails.env.development?
end

Rack::Attack.safelist("req/allow/internal") do |req|
  WHITELISTED_DOMAINS.include?(req.host)
end

ip_limiter = lambda do |req|
  matches = req.path.match /^\/v\d+\/accounts\/([^\/]+)\//
  account = matches[1] unless matches.nil?
  ip = req.fetch_header('cf-connecting-ip') { req.ip }

  if account.present?
    "#{account}/#{ip}"
  else
    ip
  end
end

Rack::Attack.throttle("req/ip/burst/30s", { limit: 50, period: 30.seconds }, &ip_limiter)
Rack::Attack.throttle("req/ip/burst/2m", { limit: 100, period: 2.minutes }, &ip_limiter)
Rack::Attack.throttle("req/ip/burst/5m", { limit: 200, period: 5.minutes }, &ip_limiter)
Rack::Attack.throttle("req/ip/burst/10m", { limit: 500, period: 10.minutes }, &ip_limiter)

Rack::Attack.blocklist("req/block/ip") do |req|
  ip = req.fetch_header('cf-connecting-ip') { req.ip }

  !Rack::Attack.cache.read("req/block/ip:#{ip}").nil?
end

Rack::Attack.throttled_response = -> (env) {
  match_data = env["rack.attack.match_data"] || {}
  match_key = env['rack.attack.matched'] || ''

  window = match_key.split('/').last
  count = match_data[:count].to_i
  period = match_data[:period].to_i
  limit = match_data[:limit].to_i
  now = Time.current

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
        detail: "Throttle limit has been reached for your IP address. Please see https://keygen.sh/docs/api#rate-limiting for more info."
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
        detail: "Your IP address has been temporarily blacklisted due to abusive behavior. Please see https://keygen.sh/docs/api#rate-limiting for more info."
      }]
    }.to_json]
  ]
}
