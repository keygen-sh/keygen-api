module TokenAuthentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods

  def authenticate_with_token!
    @current_bearer = authenticate_or_request_with_http_token &method(:authenticator)
  end

  def authenticate_with_token
    @current_bearer = authenticate_with_http_token &method(:authenticator)
  end

  private

  def authenticator(token, options)
    return if current_account.nil?

    # Make sure token matches our expected format. This is also here to help users
    # who may be mistakenly using a UUID as a token, which is a common mistake.
    if token.present? && token =~ UUID_REGEX
      render_unauthorized code: 'TOKEN_FORMAT_INVALID', detail: "Token format is invalid (make sure the token begins with a proper prefix e.g. 'prod-XXX' or 'acti-XXX', and that it's not a token UUID)" and return
    end

    @current_token = TokenAuthenticationService.new(
      account: current_account,
      token: token
    ).execute

    if current_token&.expired?
      render_unauthorized code: 'TOKEN_EXPIRED', detail: "Token is expired" and return
    end

    current_token&.bearer
  end

  def request_http_token_authentication(realm = "Keygen", message = nil)
    headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")

    raise Keygen::Error::UnauthorizedError
  end
end
