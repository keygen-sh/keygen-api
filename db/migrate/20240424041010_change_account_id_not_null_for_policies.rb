class ChangeAccountIdNotNullForPolicies < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :policies, :account_id, false
    remove_check_constraint :policies, name: 'policies_account_id_not_null'
  end
end
