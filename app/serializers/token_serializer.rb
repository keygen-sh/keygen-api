class TokenSerializer < BaseSerializer
  type :tokens

  attributes [
    :token,
    :created,
    :updated
  ]

  belongs_to :bearer, polymorphic: true

  def token
    object.raw
  end
end
