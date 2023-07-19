# frozen_string_literal: true

# NOTE(ezekg) This saves us the headache of busting caches when
#             upgrading Rails (which caused downtime before)
rails_major_version = Rails.version.split('.').first

CACHE_KEY_VERSION = "v#{rails_major_version}"
