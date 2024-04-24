class ChangeProductIdNotNullForPolicies < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :policies, :product_id, false
    remove_check_constraint :policies, name: 'policies_product_id_not_null'
  end
end
