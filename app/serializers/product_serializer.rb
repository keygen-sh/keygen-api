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
#  id         :integer          not null, primary key
#  name       :string
#  account_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  platforms  :jsonb
#  metadata   :jsonb
#
# Indexes
#
#  index_products_on_account_id         (account_id)
#  index_products_on_account_id_and_id  (account_id,id)
#  index_products_on_deleted_at         (deleted_at)
#
