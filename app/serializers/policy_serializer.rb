class PolicySerializer < BaseSerializer
  attributes :id, :name, :price, :duration, :strict, :recurring, :floating,
             :use_pool, :pool

  belongs_to :product
  has_many :licenses

  def id
    object.hashid
  end
end
