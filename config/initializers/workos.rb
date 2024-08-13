# frozen_string_literal: true

WORKOS_CLIENT_ID = ENV['WORKOS_CLIENT_ID']
WORKOS_API_KEY   = ENV['WORKOS_API_KEY']

WorkOS.configure do |config|
  config.key = WORKOS_API_KEY
end
