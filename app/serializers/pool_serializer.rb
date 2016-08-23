class PoolSerializer < BaseSerializer
  type :pools

  attributes [
    :id,
    :key,
    :created,
    :updated
  ]

  belongs_to :account
  belongs_to :policy
end
