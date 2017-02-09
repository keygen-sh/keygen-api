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
    account = current_account || Account.find(params[:account_id] || params[:id])

    tok = TokenAuthenticationService.new(
      account: account,
      token: token
    ).execute

    if tok&.expired?
      render_unauthorized detail: "is expired", source: {
        pointer: "/data/relationships/tokens" } and return
    end

    tok&.bearer
  end

  def request_http_token_authentication(realm = "Application", message = nil)
    render_unauthorized
  end
end
