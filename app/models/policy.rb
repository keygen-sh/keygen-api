class Policy < ApplicationRecord
  include Limitable
  include Pageable

  acts_as_paranoid

  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :pool, class_name: "Key", dependent: :destroy

  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  validate do
    errors.add :encrypted, "cannot be encrypted and use a pool" if pool? && encrypted?
  end

  scope :product, -> (id) { where product: Product.decode_id(id) }

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
#  id           :integer          not null, primary key
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
#  product_id   :integer
#  account_id   :integer
#  max_machines :integer
#  encrypted    :boolean          default(FALSE)
#  protected    :boolean          default(FALSE)
#  deleted_at   :datetime
#  metadata     :jsonb
#
# Indexes
#
#  index_policies_on_account_id_and_id          (account_id,id)
#  index_policies_on_deleted_at                 (deleted_at)
#  index_policies_on_product_id_and_account_id  (product_id,account_id)
#
