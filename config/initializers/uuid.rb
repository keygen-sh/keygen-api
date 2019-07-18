# frozen_string_literal: true

UUID_REGEX = /^[0-9A-F]{8}-?[0-9A-F]{4}-?[4][0-9A-F]{3}-?[89AB][0-9A-F]{3}-?[0-9A-F]{12}$/i

# This is used throughout the app for looking up UUIDs from various tokens
UUID_LENGTH = 32
