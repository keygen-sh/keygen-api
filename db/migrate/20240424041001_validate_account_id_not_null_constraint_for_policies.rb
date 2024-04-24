class ValidateAccountIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :policies, name: 'policies_account_id_not_null'
  end
end
