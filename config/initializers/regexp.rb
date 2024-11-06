# frozen_string_literal: true

Regexp.timeout = 1

# used throughout the app to check if a value is a UUID
UUID_RE = /\A[0-9A-F]{8}-?[0-9A-F]{4}-?[4][0-9A-F]{3}-?[89AB][0-9A-F]{3}-?[0-9A-F]{12}\z/i

# above pattern without anchors for URLs
UUID_URL_RE = /[0-9A-F]{8}-?[0-9A-F]{4}-?[4][0-9A-F]{3}-?[89AB][0-9A-F]{3}-?[0-9A-F]{12}/i

# used throughout the app for checking if a value is a partial UUID
UUID_CHAR_RE = /\A[-0-9A-F]+\z/i

# used throughout the app for looking up UUIDs from various tokens
UUID_LENGTH = 32

# used to check if a value is base64 encoded
BASE64_RE = /\A(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{4}|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{2}={2})\z/

# used to check if a value is hex encoded
HEX_RE = /\A(0x)?\p{Hex_Digit}+\z/
