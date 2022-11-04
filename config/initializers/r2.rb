# frozen_string_literal: true

##
# Cloudflare R2 configuration
CF_ACCESS_KEY_ID     = ENV.fetch('CF_ACCESS_KEY_ID')
CF_SECRET_ACCESS_KEY = ENV.fetch('CF_SECRET_ACCESS_KEY')
CF_ACCOUNT_ID        = ENV.fetch('CF_ACCOUNT_ID')
CF_BUCKET            = ENV.fetch('CF_BUCKET')
CF_REGION            = ENV.fetch('CF_REGION')

CF_CLIENT_OPTIONS = {
  access_key_id: CF_ACCESS_KEY_ID,
  secret_access_key: CF_SECRET_ACCESS_KEY,
  endpoint: "https://#{CF_ACCOUNT_ID}.r2.cloudflarestorage.com",
  region: CF_REGION,
}.freeze
