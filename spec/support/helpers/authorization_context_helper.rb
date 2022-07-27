# frozen_string_literal: true

module AuthorizationContextHelper
  def authorization_context(account:, bearer: nil, token: nil)
    AuthorizationContext.new(account:, bearer:, token:)
  end
end
