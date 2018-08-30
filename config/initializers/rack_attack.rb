WHITELISTED_DOMAINS = %w[dist.keygen.sh]

Rack::Attack.safelist("req/allow/localhost") do |req|
  "127.0.0.1" == req.ip || "::1" == req.ip unless Rails.env.development?
end

Rack::Attack.safelist("req/allow/internal") do |req|
  WHITELISTED_DOMAINS.include?(req.host)
end

ip_limiter = lambda do |req|
  matches = req.path.match /^\/v\d+\/accounts\/([^\/]+)\//
  account = matches[1] unless matches.nil?

  if account.present?
    "#{account}/#{req.ip}"
  else
    req.ip
  end
end

Rack::Attack.throttle("req/ip/burst/10s", { limit: 50, period: 10.seconds }, &ip_limiter)
Rack::Attack.throttle("req/ip/burst/5m", { limit: 300, period: 5.minutes }, &ip_limiter)

Rack::Attack.blocklist("req/block/ip") do |req|
  !Rack::Attack.cache.read("req/block/ip:#{req.ip}").nil?
end

Rack::Attack.throttled_response = -> (env) {
  match_data = env["rack.attack.match_data"] || {}
  period = match_data[:period].to_i
  limit = match_data[:limit].to_i
  now = Time.current

  [
    429,
    {
      "Content-Type" => "application/vnd.api+json",
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
