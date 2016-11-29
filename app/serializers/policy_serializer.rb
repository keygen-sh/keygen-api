class PolicySerializer < BaseSerializer
  type :policies

  attributes :id,
             :name,
             :price,
             :duration,
             :strict,
             :recurring,
             :floating,
             :max_machines,
             :use_pool,
             :protected,
             :metadata,
             :created,
             :updated

  belongs_to :product
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
