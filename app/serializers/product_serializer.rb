class ProductSerializer < BaseSerializer
  type :products

  attributes :id,
             :name,
             :platforms,
             :metadata,
             :created,
             :updated
end

# == Schema Information
#
# Table name: products
#
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  platforms  :jsonb
#  metadata   :jsonb
#  id         :uuid             not null, primary key
#  account_id :uuid
#
# Indexes
#
#  index_products_on_account_id  (account_id)
#  index_products_on_created_at  (created_at)
#  index_products_on_deleted_at  (deleted_at)
#  index_products_on_id          (id)
#
