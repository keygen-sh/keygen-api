# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'online_cutover'

OnlineCutover.configure do |config|
  config.enabled = Keygen.server? || Keygen.worker?

  config.replica_available = -> { Keygen.database.read_replica_available? }
  config.replica_enabled   = -> { Keygen.database.read_replica_enabled? }

  config.quiesce_timeout = ENV.fetch('ONLINE_CUTOVER_QUIESCE_TIMEOUT') { 30 }.to_i
end
