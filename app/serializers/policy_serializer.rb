class PolicySerializer < BaseSerializer
  attributes :id, :name, :price, :duration, :strict, :recurring, :floating,
             :max_activations, :use_pool, :pool, :created, :updated

  belongs_to :product
  has_many :licenses

  def id
    object.hashid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
