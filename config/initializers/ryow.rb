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
    account_id    = request.path[/^\/v\d+\/accounts\/([^\/]+)\//, 1] # FIXME(ezekg) use account ID
    session_authn = request.headers['Cookie']                        # FIXME(ezekg) use session ID
    token_authn   = request.headers['Authorization']                 # FIXME(ezekg) use token ID

    # FIXME(ezekg) use bearer ID?
    [account_id, session_authn, token_authn, request.remote_ip]
  }
end
