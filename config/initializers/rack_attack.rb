class Rack::Attack
  WHITELISTED_DOMAINS = %w[
    dist.keygen.sh
    api.keygen.sh
    keygen.sh
  ]

  # Allow all local traffic
  safelist("allow-localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  # All all internal traffic
  safelist("allow-internal") do |req|
    WHITELISTED_DOMAINS.include?(req.host)
  end

  # Allow an IP address to make up to 100 requests every 10 seconds
  throttle("req/ip/burst", limit: 100, period: 10.seconds) do |req|
    req.ip
  end

  # Allow an IP address to make up to 1000 requests every hour
  throttle("req/ip/hour", limit: 1000, period: 1.hour) do |req|
    req.ip
  end

  # Send the following response to throttled clients
  self.throttled_response = -> (env) {
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
end
