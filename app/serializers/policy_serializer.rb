class PolicySerializer < BaseSerializer
  attributes :id, :name, :price, :duration, :strict, :recurring, :floating,
             :use_pool, :pool
  belongs_to :account
  has_many :licenses
end
