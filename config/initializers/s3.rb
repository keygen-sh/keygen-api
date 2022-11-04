# frozen_string_literal: true

##
# AWS S3 configuration
AWS_ACCESS_KEY_ID     = ENV.fetch('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY')
AWS_BUCKET            = ENV.fetch('AWS_BUCKET')
AWS_REGION            = ENV.fetch('AWS_REGION')

AWS_CLIENT_OPTIONS = {
  access_key_id: AWS_ACCESS_KEY_ID,
  secret_access_key: AWS_SECRET_ACCESS_KEY,
  endpoint: "https://#{AWS_BUCKET}.s3.#{AWS_REGION}.amazonaws.com",
  region: AWS_REGION,
}.freeze
