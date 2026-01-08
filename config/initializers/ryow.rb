# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

ReadYourOwnWrites.configure do |config|
  config.ignored_request_paths = [
    %r{/actions/validate-key\z},
    %r{/search\z},
  ]

  # extract tenant (account) from request path for client identifier
  config.client_identifier = -> request {
    account_id    = request.path[/^\/v\d+\/accounts\/([^\/]+)\//, 1]
    session_authn = request.headers['Cookie']
    token_authn   = request.headers['Authorization']

    [account_id, session_authn, token_authn, request.remote_ip]
  }
end
