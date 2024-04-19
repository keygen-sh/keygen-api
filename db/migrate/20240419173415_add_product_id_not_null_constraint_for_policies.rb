class AddProductIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :policies, 'product_id IS NOT NULL', name: 'policies_product_id_null', validate: false
  end
end
