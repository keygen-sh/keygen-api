# frozen_string_literal: true

# NOTE(ezekg) This saves us the headache of busting caches when upgrading
#             Rails (which has caused downtime before).
rails_major_version, rails_minor_version, * = Rails.version.split('.')

CACHE_KEY_VERSION = "v#{rails_major_version}.#{rails_minor_version}"
