# frozen_string_literal: true

StrongMigrations.tap do |config|
  # migrations created prior to installing the gem are safe
  config.start_after = 20240403173726

  # timeouts
  config.lock_timeout      = 10.seconds
  config.statement_timeout = 1.hour
end
