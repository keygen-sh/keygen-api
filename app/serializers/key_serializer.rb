class KeySerializer < BaseSerializer
  type :keys

  attributes [
    :id,
    :key,
    :created,
    :updated
  ]

  belongs_to :account
  belongs_to :policy
end
