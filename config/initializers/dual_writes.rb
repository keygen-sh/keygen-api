# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'dual_writes'

DualWrites.configure do |config|
  config.retry_attempts = Rails.env.test? ? 0 : 10 # disable retries in test
end
