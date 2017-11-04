class Rack::Attack

  # `Rack::Attack` is configured to use the `Rails.cache` value by default,
  # but you can override that by setting the `Rack::Attack.cache.store` value
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Allow all local traffic
  safelist("allow-localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  # Allow an IP address to make 100 requests every 10 seconds
  throttle("req/ip", limit: 100, period: 10.seconds) do |req|
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
