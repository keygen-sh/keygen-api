class ValidateProductIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :policies, name: 'policies_product_id_not_null'
  end
end
