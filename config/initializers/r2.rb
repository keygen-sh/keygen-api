# frozen_string_literal: true

##
# Cloudflare R2 configuration
R2_ACCESS_KEY_ID     = ENV.fetch('R2_ACCESS_KEY_ID')
R2_SECRET_ACCESS_KEY = ENV.fetch('R2_SECRET_ACCESS_KEY')
R2_ACCOUNT_ID        = ENV.fetch('R2_ACCOUNT_ID')
R2_BUCKET            = ENV.fetch('R2_BUCKET')
R2_REGION            = ENV.fetch('R2_REGION')

R2_CLIENT_OPTIONS = {
  access_key_id: R2_ACCESS_KEY_ID,
  secret_access_key: R2_SECRET_ACCESS_KEY,
  endpoint: "https://#{R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
  region: R2_REGION,
}.freeze
