# frozen_string_literal: true

##
# AWS S3 configuration
AWS_ACCESS_KEY_ID     = ENV['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = ENV['AWS_SECRET_ACCESS_KEY']
AWS_BUCKET            = ENV['AWS_BUCKET']
AWS_REGION            = ENV['AWS_REGION']
AWS_ENDPOINT_URL_S3   = ENV['AWS_ENDPOINT_URL_S3']

AWS_CLIENT_OPTIONS = {
  access_key_id: AWS_ACCESS_KEY_ID,
  secret_access_key: AWS_SECRET_ACCESS_KEY,
  region: AWS_REGION,
  endpoint: AWS_ENDPOINT_URL_S3
}.freeze
