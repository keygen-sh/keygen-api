# frozen_string_literal: true

# This is used throughout the app to check if a value is a UUID
UUID_RX = /^[0-9A-F]{8}-?[0-9A-F]{4}-?[4][0-9A-F]{3}-?[89AB][0-9A-F]{3}-?[0-9A-F]{12}$/i

# This is used throughout the app for checking if a value is a partial UUID
UUID_CHAR_RX = /^[-0-9A-F]+$/i

# This is used throughout the app for looking up UUIDs from various tokens
UUID_LENGTH = 32
