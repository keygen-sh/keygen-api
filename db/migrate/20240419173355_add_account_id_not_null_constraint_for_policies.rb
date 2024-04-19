class AddAccountIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :policies, 'account_id IS NOT NULL', name: 'policies_account_id_null', validate: false
  end
end
