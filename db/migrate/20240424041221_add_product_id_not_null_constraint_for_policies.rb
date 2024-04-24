class AddProductIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :policies, 'product_id IS NOT NULL', name: 'policies_product_id_not_null', validate: false
  end
end
