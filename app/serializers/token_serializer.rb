class TokenSerializer < BaseSerializer
  type :tokens

  attributes [
    :auth_token,
    :reset_token
  ]

  belongs_to :bearer, polymorphic: true
end
