class Policy < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :pool, class_name: "Key", dependent: :destroy

  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  validate do
    errors.add :encrypted, "cannot be encrypted and use a pool" if pool? && encrypted?
  end

  scope :product, -> (id) { where product: id }

  def pool?
    use_pool
  end

  def encrypted?
    encrypted
  end

  def protected?
    protected
  end

  def pop!
    return nil if pool.empty?
    key = pool.first.destroy
    return key
  rescue ActiveRecord::StaleObjectError
    reload
    retry
  end
end

# == Schema Information
#
# Table name: policies
#
#  id           :uuid             not null, primary key
#  name         :string
#  price        :integer
#  duration     :integer
#  strict       :boolean          default(FALSE)
#  recurring    :boolean          default(FALSE)
#  floating     :boolean          default(TRUE)
#  use_pool     :boolean          default(FALSE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  lock_version :integer          default(0), not null
#  max_machines :integer
#  encrypted    :boolean          default(FALSE)
#  protected    :boolean          default(FALSE)
#  deleted_at   :datetime
#  metadata     :jsonb
#  product_id   :uuid
#  account_id   :uuid
#
# Indexes
#
#  index_policies_on_account_id  (account_id)
#  index_policies_on_product_id  (product_id)
#
