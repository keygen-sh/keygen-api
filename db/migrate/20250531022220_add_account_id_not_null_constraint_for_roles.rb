class AddAccountIdNotNullConstraintForRoles < ActiveRecord::Migration[7.2]
  verbose!

  def up
    add_check_constraint :roles, 'account_id IS NOT NULL', name: 'roles_account_id_not_null', validate: false
  end
end
