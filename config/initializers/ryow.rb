# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

ReadYourOwnWrites.configure do |config|
  config.ignored_request_paths = [
    %r{/actions/validate-key\z},
    %r{/search\z},
  ]

  # NB(ezekg) This is run BEFORE the Rails app via Rails' DatabaseSelector
  #           middleware, so things like route params are NOT available.
  #
  # extract tenant (account) from request path for client identifier
  config.client_identifier = -> request {
    account_id = request.path[/^\/v\d+\/accounts\/([^\/]+)\//, 1] # FIXME(ezekg) use account ID
    session_id = request.cookie_jar.encrypted[:session_id]
    auth_value = request.authorization || request.query_parameters[:token] || request.query_parameters[:auth]

    [account_id, session_id, auth_value, request.remote_ip]
  }
end
