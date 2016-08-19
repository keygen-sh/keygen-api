class TokenSerializer < BaseSerializer
  type "tokens"

  attributes [
    :auth_token,
    :reset_auth_token
  ]
end
