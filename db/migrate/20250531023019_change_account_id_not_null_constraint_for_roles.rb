class ChangeAccountIdNotNullConstraintForRoles < ActiveRecord::Migration[7.2]
  verbose!

  def up
    change_column_null :roles, :account_id, false
    remove_check_constraint :roles, name: 'roles_account_id_not_null'
  end
end
