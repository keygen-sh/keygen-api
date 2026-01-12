# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

ReadYourOwnWrites.configure do |config|
  config.ignored_request_paths = [
    %r{/actions/validate-key\z},
    %r{/search\z},
  ]

  # NB(ezekg) This is run BEFORE the Rails app via Rails' DatabaseSelector
  #           middleware, so things like route params are NOT available.
  config.client_identifier = -> request {
    account_id = request.path[/^\/v\d+\/accounts\/([^\/]+)\/?/, 1] # FIXME(ezekg) use resolved account ID
    session_id = request.cookie_jar.encrypted[:session_id]
    auth_value = request.authorization || request.query_parameters[:token] || request.query_parameters[:auth]

    id = [request.host, account_id, session_id, auth_value, request.remote_ip].join(':')

    ReadYourOwnWrites::ClientIdentity.new(id:)
  }

  # Build RESTful resource segments from the request path. Each segment
  # represents a resource boundary in the URL hierarchy.
  #
  # For example, /v1/accounts/abc/licenses/xyz/actions/validate becomes:
  #   ['v1/accounts/abc', 'v1/accounts/abc/licenses/xyz']
  #
  # This ensures writes to a resource affect reads to:
  #   - The same resource (exact match)
  #   - Parent resources (e.g., listing endpoints)
  #   - Child resources (e.g., nested actions)
  #
  config.request_path_resolver = -> request {
    parts = request.path.split('/').reject(&:blank?)[1..] # drop version prefix

    # Build segments by pairing resource type with ID (e.g., ['accounts', 'abc'] -> 'accounts/abc')
    segments = parts.each_slice(2).each_with_object([]) { |pair, acc|
      scope = [acc.last, pair.join('/')].compact.join('/')
      acc << scope
    }

    pp(segments:)

    ReadYourOwnWrites::RequestPath.new(segments:)
  }
end
