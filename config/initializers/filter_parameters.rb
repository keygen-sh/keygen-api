# frozen_string_literal: true

FILTER_KEYS = %i[passw digest priv key token secret crypt salt certificate otp redirect cvv cvc ssn auth]

# sensitive values that can live under an otherwise benign key, e.g. a second
# factor's otpauth:// uri or a token (see Token#generate! for token formats)
FILTER_VALUES = [
  %r{\botpauth://}i,
  /\b(?:env|prod|admin|user|activ|dev|sales|spprt|read|token)-\h{32,}v3\b/,
  /\b(?:envi|prod|admi|user|acti|deve|sale|supp|read|orph)-\h{30,}v2\b/,
  /\b\h{32}\.\h{32}\.\h{30,}v1\b/,
].freeze

# configure sensitive parameters to be filtered from loggers
Rails.application.config.filter_parameters += FILTER_KEYS
