# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'slack'

SLACK_SIGNING_SECRET = ENV['SLACK_SIGNING_SECRET']
SLACK_TOKEN          = ENV['SLACK_TOKEN']
SLACK_ADMIN_EMAIL    = ENV['SLACK_ADMIN_EMAIL']
SLACK_TEAM_ID        = ENV['SLACK_TEAM_ID']
