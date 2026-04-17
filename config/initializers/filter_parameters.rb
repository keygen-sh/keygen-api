# frozen_string_literal: true

FILTER_KEYS = %i[passw digest priv key token secret crypt salt certificate otp redirect cvv cvc ssn auth]

# configure sensitive parameters to be filtered from loggers
Rails.application.config.filter_parameters += FILTER_KEYS
