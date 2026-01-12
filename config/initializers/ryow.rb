# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

ReadYourOwnWrites.configure do |config|
  config.ignored_request_paths = [
    %r{/actions/validate-key\z},
    %r{/actions/validate\z},
    %r{/search\z},
  ]

  # NB(ezekg) this is run BEFORE the rails app via rails' DatabaseSelector
  #           middleware i.e. things like route params are NOT available
  config.client_identifier = -> request {
    account_id  = request.path[/^\/v\d+\/accounts\/([^\/]+)\/?/, 1] # FIXME(ezekg) use resolved account ID
    session_id  = request.cookie_jar.encrypted[:session_id]
    auth        = request.authorization || request.query_parameters[:token] || request.query_parameters[:auth]
    fingerprint = [request.host, account_id, session_id, auth, request.remote_ip].join(':')

    ReadYourOwnWrites::Client.new(fingerprint:)
  }
end
