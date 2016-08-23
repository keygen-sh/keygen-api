class TokenSerializer < BaseSerializer
  type :tokens

  attributes [
    :auth_token,
    :reset_token,
    :created,
    :updated
  ]

  belongs_to :bearer, polymorphic: true
end
