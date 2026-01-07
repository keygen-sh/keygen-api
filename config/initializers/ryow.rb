# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

ReadYourOwnWrites.configure do |config|
  config.ignored_request_paths = [
    %r{/actions/validate-key\z},
    %r{/search\z},
  ]

  # extract tenant (account) from request path for client identifier
  config.client_identifier = ->(request) {
    account_id = request.path[/^\/v\d+\/accounts\/([^\/]+)\//, 1]

    [account_id, request.authorization, request.remote_ip]
  }
end
