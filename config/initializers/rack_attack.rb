class Rack::Attack

  # `Rack::Attack` is configured to use the `Rails.cache` value by default,
  # but you can override that by setting the `Rack::Attack.cache.store` value
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Allow all local traffic
  safelist('allow-localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Allow an IP address to make 5 requests every 1 second
  throttle('req/ip', limit: 5, period: 1.second) do |req|
    req.ip
  end

  # Send the following response to throttled clients
  self.throttled_response = -> (env) {
    retry_after = (env['rack.attack.match_data'] || {})[:period].to_i rescue 0
    [
      429,
      { 'Content-Type' => 'application/vnd.api+json', 'Retry-After' => retry_after.to_s },
      [{
        'errors': [{
          'title': 'Throttle limit reached',
          'detail': 'Throttle limit has been reached for your IP address. Please see https://keygen.sh/docs/api#rate-limiting for more info.'
        }]
      }.to_json]
    ]
  }
end
