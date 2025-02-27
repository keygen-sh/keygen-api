# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  max_age = 1.day.to_i
  expose  = %w[
    keygen-accept-signature
    keygen-signature
    keygen-date
    keygen-digest
    keygen-account-id
    keygen-bearer-id
    keygen-token-id
    x-ratelimit-window
    x-ratelimit-count
    x-ratelimit-limit
    x-ratelimit-remaining
    x-ratelimit-reset
    x-request-id
    x-signature
    date
    digest
  ]

  options = {
    headers: :any,
    methods: :any,
    max_age:,
    expose:,
  }

  allow do
    origins { _1.ends_with?(Keygen::DOMAIN) }

    resource '*', **options, credentials: true
  end

  allow do
    origins '*'

    resource '*', **options
  end
end
