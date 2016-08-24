class PolicySerializer < BaseSerializer
  type :policies

  attributes [
    :id,
    :name,
    :price,
    :duration,
    :strict,
    :recurring,
    :floating,
    :max_machines,
    :use_pool,
    :created,
    :updated
  ]

  belongs_to :product
  has_many :licenses
  has_many :pool, class_name: "Key"
end
