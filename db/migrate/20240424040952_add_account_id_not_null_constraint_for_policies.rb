class AddAccountIdNotNullConstraintForPolicies < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :policies, 'account_id IS NOT NULL', name: 'policies_account_id_not_null', validate: false
  end
end
