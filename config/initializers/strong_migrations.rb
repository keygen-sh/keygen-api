# frozen_string_literal: true

StrongMigrations.tap do |config|
  config.lock_timeout      = 10.seconds
  config.statement_timeout = 1.hour
end
