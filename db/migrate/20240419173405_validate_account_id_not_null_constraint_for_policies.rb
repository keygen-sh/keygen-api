class ValidateAccountIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :policies, name: 'policies_account_id_null'

    change_column_null :policies, :account_id, false
    remove_check_constraint :policies, name: 'policies_account_id_null'
  end
end
