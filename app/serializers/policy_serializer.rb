class PolicySerializer < BaseSerializer
  attributes :id, :name, :price, :duration, :strict, :recurring, :floating,
             :max_activations, :use_pool, :pool

  belongs_to :product
  has_many :licenses

  def id
    object.hashid
  end
end
