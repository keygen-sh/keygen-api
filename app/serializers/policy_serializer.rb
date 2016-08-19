class PolicySerializer < BaseSerializer
  type "policies"

  attributes [
    :id,
    :name,
    :price,
    :duration,
    :strict,
    :recurring,
    :floating,
    :max_activations,
    :use_pool,
    :pool,
    :created,
    :updated
  ]

  belongs_to :product
  has_many :licenses
end
