# frozen_string_literal: true

module TokenAuthentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  def authenticate_with_token!
    @current_bearer =
      case
      when has_bearer_credentials?
        authenticate_or_request_with_http_token(&method(:http_token_authenticator))
      when has_basic_credentials?
        authenticate_or_request_with_http_basic(&method(:http_basic_authenticator))
      else
        authenticate_or_request_with_query_token(&method(:query_token_authenticator))
      end
  end

  def authenticate_with_token
    @current_bearer =
      case
      when has_bearer_credentials?
        authenticate_with_http_token(&method(:http_token_authenticator))
      when has_basic_credentials?
        authenticate_with_http_basic(&method(:http_basic_authenticator))
      else
        authenticate_with_query_token(&method(:query_token_authenticator))
      end
  end

  private

  attr_accessor :current_http_token

  def authenticate_or_request_with_query_token(&auth_procedure)
    authenticate_with_query_token(&auth_procedure) || request_http_token_authentication
  end

  def authenticate_with_query_token(&auth_procedure)
    query_token = request.query_parameters[:token]

    auth_procedure.call(query_token)
  end

  def query_token_authenticator(query_token)
    return if
      current_account.nil? || query_token.blank?

    http_token_authenticator(query_token)
  end

  def http_basic_authenticator(username = nil, password = nil)
    return if
      current_account.nil? || username.blank? || password.present?

    http_token_authenticator(username)
  end

  def http_token_authenticator(http_token = nil, options = nil)
    return if
      current_account.nil? || http_token.blank?

    # Make sure token matches our expected format. This is also here to help users
    # who may be mistakenly using a UUID as a token, which is a common mistake.
    if http_token.present? && http_token =~ UUID_REGEX
      render_unauthorized(
        detail: "Token format is invalid (make sure the token begins with a proper prefix e.g. 'admin-XXX', 'prod-XXX' or 'activ-XXX', and that it's not a token's UUID identifier)",
        code: 'TOKEN_FORMAT_INVALID',
      )

      return
    end

    @current_http_token = http_token
    @current_token      = TokenAuthenticationService.call(
      account: current_account,
      token: http_token
    )

    current_bearer = current_token&.bearer

    if (current_bearer.present? && current_bearer.account_id != current_account.id) ||
       (current_token.present? && current_token.account_id != current_account.id)
      Keygen.logger.error "[authentication] Account mismatch: account=#{current_account&.id || 'N/A'} token=#{current_token&.id || 'N/A'} bearer=#{current_bearer&.id || 'N/A'}"

      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
    end

    Keygen::Store::Request.store[:current_token]  = current_token
    Keygen::Store::Request.store[:current_bearer] = current_bearer

    if current_token&.expired?
      render_unauthorized code: 'TOKEN_EXPIRED', detail: 'Token is expired' and return
    end

    current_token&.bearer
  end

  def request_http_token_authentication(realm = 'keygen', message = nil)
    headers['WWW-Authenticate'] = %(Bearer realm="#{realm.gsub(/"/, "")}")

    case
    when current_http_token.blank?
      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_BLANK')
    else
      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
    end
  end

  def request_http_basic_authentication(realm = 'keygen', message = nil)
    headers['WWW-Authenticate'] = %(Bearer realm="#{realm.gsub(/"/, "")}")

    raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
  end

  def has_bearer_credentials?
    authentication_scheme == 'bearer'
  end

  def has_basic_credentials?
    authentication_scheme == 'basic'
  end

  def authentication_scheme
    return nil unless
      request.authorization.present?

    auth_parts  = request.authorization.to_s.split(' ', 2)
    auth_scheme = auth_parts.first
    return nil if
      auth_scheme.nil?

    auth_scheme.downcase
  end
end
