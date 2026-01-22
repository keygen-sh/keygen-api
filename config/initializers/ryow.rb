# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

ReadYourOwnWrites.configure do |config|
  config.ignored_request_paths = [
    %r{/actions/validate-key\z},
    %r{/actions/validate\z},
    %r{/search\z},
  ]

  # NB(ezekg) for backwards compatibility, we don't want to require a read replica,
  #           so ryow will only attempt to connect to one if it's available and
  #           enabled (both of which can be configured via the ENV)
  config.read_replica_available = -> { Keygen.database.read_replica_available? }
  config.read_replica_enabled   = -> { Keygen.database.read_replica_enabled? }

  # NB(ezekg) this is run BEFORE the rails app via rails' DatabaseSelector
  #           middleware i.e. things like route params are NOT available
  config.client_identifier = -> request {
    account_id  = request.path[/^\/v\d+\/accounts\/([^\/]+)\/?/, 1] # FIXME(ezekg) use resolved account ID
    session_id  = request.cookie_jar.encrypted[:session_id]
    auth        = request.authorization || request.query_parameters[:token] || request.query_parameters[:auth]
    fingerprint = Digest::SHA2.hexdigest(
      [request.host, request.remote_ip, account_id, session_id, auth].join(':'),
    )

    ReadYourOwnWrites::Client.new(fingerprint:)
  }
end
