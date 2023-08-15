# frozen_string_literal: true

# This is used throughout the app to check if a value is a UUID
UUID_RE = /\A[0-9A-F]{8}-?[0-9A-F]{4}-?[4][0-9A-F]{3}-?[89AB][0-9A-F]{3}-?[0-9A-F]{12}\z/i

# Above pattern without anchors for URLs
UUID_URL_RE = /[0-9A-F]{8}-?[0-9A-F]{4}-?[4][0-9A-F]{3}-?[89AB][0-9A-F]{3}-?[0-9A-F]{12}/i

# This is used throughout the app for checking if a value is a partial UUID
UUID_CHAR_RE = /\A[-0-9A-F]+\z/i

# This is used throughout the app for looking up UUIDs from various tokens
UUID_LENGTH = 32
