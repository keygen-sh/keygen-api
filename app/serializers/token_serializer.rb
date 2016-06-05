class TokenSerializer < BaseSerializer
  attributes :auth_token, :reset_auth_token

  def id
    object.hashid
  end
end
