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
end

# == Schema Information
#
# Table name: policies
#
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
#  id           :uuid             not null, primary key
#  product_id   :uuid
#  account_id   :uuid
#
# Indexes
#
#  index_policies_on_account_id  (account_id)
#  index_policies_on_created_at  (created_at)
#  index_policies_on_deleted_at  (deleted_at)
#  index_policies_on_id          (id)
#  index_policies_on_product_id  (product_id)
#
