# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[
  password
  token
  passw
  secret
  private_key
  salt
  otp
  ssn
  auth
]
