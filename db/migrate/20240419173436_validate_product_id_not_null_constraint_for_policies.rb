class ValidateProductIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :policies, name: 'policies_product_id_null'

    change_column_null :policies, :product_id, false
    remove_check_constraint :policies, name: 'policies_product_id_null'
  end
end
